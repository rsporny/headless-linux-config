# Headless Linux Bootstrap Scripts

Fastrack dev configuration for headless Linux VMs (no X/Wayland display,
accessed over SSH). Adapted from [macos-config](https://github.com/rsporny/macos-config).

## Phase 0
- spin up the VM (Ubuntu; aarch64 assumed for Apple-silicon Parallels)
- restore `~/.gnupg` and `~/.ssh` from backup
- install [Homebrew](https://brew.sh) (linuxbrew) and make sure
  `/home/linuxbrew/.linuxbrew/bin/brew` is on `PATH`
- plug in the YubiKey (USB passthrough for VMs)

## Bootstrap a new machine
```
make all                       # restore + install + settings + gpg
```
or set the hostname:
```
make all HOST_NAME=my-new-vm
```

Targets can also be run individually: `make restore`, `make install`,
`make settings`, `make gpg`. `make backup` copies your live dotfiles back into
`dotfiles/`; `make clean` backs up then removes them from `$HOME`.

## Clipboard & links over SSH (OSC 52)
A headless box has no clipboard of its own, so copy/paste is routed to the
**host terminal** via the OSC 52 escape sequence over SSH. This needs a
terminal emulator that supports OSC 52 clipboard writes (e.g. Ghostty, which
allows it by default) — no `xclip`/`xsel`/`wl-clipboard` required.

- **`dotfiles/.local/bin/osc52-copy`** — reads stdin, pushes it to the host
  clipboard (handles tmux passthrough).
- **lazygit** — `y` copies to the host clipboard; `O` (open PR/link) has no
  browser here, so it copies the URL to the host clipboard for you to paste
  into your browser.
- **Neovim** — `clipboard=unnamedplus` is wired to the built-in OSC 52
  provider when `SSH_TTY` is set, so `y`/`p` use the host clipboard.

## YubiKey GPG (signed commits)
`make gpg` installs the smartcard stack (`pcscd`, `libccid`, `yubikey-manager`),
routes the card through `pcscd` (not scdaemon's internal CCID), masks the
systemd system gpg-agent so brew's agent runs, and installs the udev + polkit
rules that let an SSH session (no seat) reach the reader.

- Test: `gpg --card-status`
- Warm the PIN cache in a real shell before committing in lazygit —
  `pinentry-curses` can't render over a TUI.
- The card requires a physical touch per signature (UIF Sign=on).
- If the reader wedges, physically unplug/replug the YubiKey.
- `pcsc-driver` in `scdaemon.conf` is arch-specific — edit it for x86_64 hosts.

