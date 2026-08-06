# Variables
SHELL_FILE := /etc/shells

# List of dotfiles to backup/restore
DOTFILES = \
    .config/git/config \
    .config/fish/config.fish \
    .config/lazygit/config.yml \
    .gnupg/gpg-agent.conf \
    .gnupg/scdaemon.conf \
    .config/direnv/direnv.toml \
    .config/nvim \
    .local/bin/osc52-copy

BACKUP_DIR = dotfiles


# Print section header
define print_header
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "$(1)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
endef


# Targets
all: restore install settings gpg

backup:
	$(call print_header,💾 Backing up dotfiles to '$(BACKUP_DIR)'...)
	@for file in $(DOTFILES); do \
		src="$(HOME)/$$file"; \
		dest="$(BACKUP_DIR)/$$file"; \
		if [ -e "$$src" ]; then \
			mkdir -p "$$(dirname $$dest)"; \
			if [ -d "$$src" ]; then \
				cp -av "$$src" "$$(dirname $$dest)"; \
			else \
				cp -v "$$src" "$$dest"; \
			fi \
		else \
			echo "⚠️  Warning: $$src not found. Skipping."; \
		fi \
	done
	@echo "✅ Backup finished."

restore:
	$(call print_header,🚚 Restoring dotfiles to $(HOME)...)
	@for file in $(DOTFILES); do \
		src="$(BACKUP_DIR)/$$file"; \
		dest="$(HOME)/$$file"; \
		if [ -e "$$src" ]; then \
			mkdir -p "$$(dirname $$dest)"; \
			if [ -d "$$src" ]; then \
				cp -av "$$src" "$$(dirname $$dest)"; \
			else \
				cp -v "$$src" "$$dest"; \
			fi \
		else \
			echo "⚠️  Warning: $$src not found. Skipping."; \
		fi \
	done
	@chmod +x "$(HOME)/.local/bin/osc52-copy" 2>/dev/null || true
	@echo "✅ Dotfiles restored successfully."

install:
	$(call print_header,✨ Installing tools via Homebrew...)
	brew install fish git gnupg pinentry  # essentials (pinentry ships pinentry-curses)
	brew install neovim luarocks  # editor
	brew install lazygit lazydocker direnv ripgrep fd fzf wget  # tools
	brew install --cask claude-code
	@echo "✅ Tools installed successfully."

settings:
	$(call print_header,🚓 Setting up shell...)
	@echo "🐟 Ensuring Fish is in /etc/shells..."
	if ! grep -q "$(shell which fish)" $(SHELL_FILE); then \
		echo "$(shell which fish)" | sudo tee -a $(SHELL_FILE); \
	fi
	@echo "⚙️ Setting Fish as default shell..."
	chsh -s "$(shell which fish)"
	@echo "✅ System settings applied."

# YubiKey GPG smartcard on a headless VM. Run after `restore` (needs the
# gpg-agent.conf / scdaemon.conf dotfiles in place). Uses $(USER)/$(HOME);
# assumes a 'plugdev' group and a YubiKey (USB vendor 1050, set in the udev
# rule under system/udev/).
gpg:
	$(call print_header,🔑 Setting up YubiKey GPG smartcard...)
	@echo "📦 Installing smartcard stack..."
	sudo apt update && sudo apt install -y pcscd libccid yubikey-manager
	@echo "🔒 Fixing ~/.gnupg permissions..."
	chmod 700 $(HOME)/.gnupg
	@echo "💳 Installing udev + polkit rules..."
	sudo cp system/udev/70-yubikey-ccid.rules /etc/udev/rules.d/70-yubikey-ccid.rules
	sudo cp system/polkit/49-pcscd.rules /etc/polkit-1/rules.d/49-pcscd.rules
	sudo udevadm control --reload-rules && sudo udevadm trigger
	@echo "👥 Ensuring $(USER) is in the 'plugdev' group..."
	sudo usermod -aG plugdev $(USER)
	@echo "🧦 Masking systemd user gpg-agent units (so brew's agent runs)..."
	systemctl --user mask gpg-agent.socket gpg-agent-ssh.socket \
		gpg-agent-extra.socket gpg-agent-browser.socket gpg-agent.service
	@echo "▶️  Enabling pcscd..."
	sudo systemctl enable --now pcscd
	@echo "♻️  Reloading gpg daemons..."
	gpgconf --kill scdaemon gpg-agent || true
	@echo "✅ YubiKey GPG setup applied. Test: gpg --card-status"
	@echo "   (If the reader is wedged, physically unplug/replug the YubiKey.)"

# Rust build environment for the midnight-node project. NOT part of `all` —
# run explicitly (`make rust`) when prepping a VM to build midnight-node.
rust:
	$(call print_header,🦀 Setting up Rust build environment...)
	@echo "📦 Installing system build deps..."
	sudo apt update && sudo apt install -y clang libclang-dev protobuf-compiler pkg-config libssl-dev
	@echo "⚙️  Installing rustup (no toolchain; rust-toolchain.toml picks it)..."
	@if command -v rustup >/dev/null 2>&1; then \
		echo "rustup already installed, skipping."; \
	else \
		curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none --profile default --no-modify-path; \
	fi
	@echo "🐟 Adding ~/.cargo/bin to fish PATH (universal)..."
	fish -c 'fish_add_path -U $$HOME/.cargo/bin'
	@echo "✅ Rust ready. In the midnight-node repo, run 'rustup show' to install"
	@echo "   the pinned toolchain/targets from rust-toolchain.toml, then 'cargo build --release'."
	@echo "   (If secp256k1-sys hits a wasm32 memmove error, add the CFLAGS_wasm32"
	@echo "   '-Wno-error=implicit-function-declaration' block to ~/.cargo/config.toml.)"

# VPN / cluster-access tooling (kubectl, AWS CLI v2, StrongDM `sdm`). NOT part of
# `all` — run explicitly (`make vpn`) when a VM needs to reach the dev EKS cluster.
# kubectl + awscli come from Homebrew; sdm has no brew formula, so it uses
# StrongDM's release endpoint (returns JSON with the arch-
# specific download URL), then `sudo ./sdm install` completes a system install.
# Docs: https://docs.strongdm.com/users/client/linux
vpn:
	$(call print_header,🔐 Installing VPN / cluster-access tools...)
	@echo "📦 kubectl + AWS CLI v2 via Homebrew..."
	brew install kubernetes-cli awscli
	@echo "🔒 StrongDM CLI (sdm) via official release endpoint..."
	@if command -v sdm >/dev/null 2>&1; then \
		echo "sdm already installed ($$(command -v sdm)), skipping."; \
	else \
		command -v unzip >/dev/null 2>&1 || { sudo apt update && sudo apt install -y unzip; }; \
		command -v jq >/dev/null 2>&1 || brew install jq; \
		arch="$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"; \
		echo "⬇️  Resolving sdm download for linux/$$arch ..."; \
		url="$$(curl -fsSL "https://app.strongdm.com/release?software=sdm-cli&os=linux&arch=$$arch" | jq -r '.url')"; \
		echo "    $$url"; \
		curl -fSL -o /tmp/sdm.zip "$$url"; \
		rm -rf /tmp/sdm-cli && unzip -o /tmp/sdm.zip -d /tmp/sdm-cli; \
		( cd /tmp/sdm-cli && sudo ./sdm install ); \
		rm -rf /tmp/sdm.zip /tmp/sdm-cli; \
	fi
	@echo "✅ VPN tools installed. Verify: kubectl version --client; aws --version; sdm version"
	@echo "   Next: 'sdm login' (StrongDM), then fetch kubeconfig, e.g.:"
	@echo "   aws eks update-kubeconfig --name stl-euw1-dev-1 --region eu-west-1"

clean: backup
	$(call print_header,🧹 Removing configuration files...)
	@for file in $(DOTFILES); do \
		target="$(HOME)/$$file"; \
		if [ -e "$$target" ]; then \
			if [ -d "$$target" ]; then \
				rm -rv "$$target"; \
			else \
				rm -v "$$target"; \
			fi \
		fi \
	done
	@echo "✅ All configuration files removed."

.PHONY: all backup restore install settings gpg rust vpn clean
