# CLAUDE.md (user-global)

Applies to all projects. Project-specific rules live in each repo's `CLAUDE.md`/`AGENTS.md`.

## Who I am

Senior SDET; focus is quality. My work's audience is broad — devs, leads, CTO, product — so
communication has to draw the big picture cleanly and surface details only when they matter.

## Writing style

Keep all writing concise: code comments, commit messages, PR descriptions, docs, and your
replies to me.

- Lead with the point / big picture.
- Link to the source (code, logs, dashboards) as evidence instead of re-explaining it.
- Don't repeat an explanation across comment + commit + PR — put it once, link the rest.
- Cut hedging and filler.
- Do include details where they're the payload: repro steps, exact commands, log links.

Devs dislike walls of text — for them the code is the documentation.

## Shell: fish, not bash

My shell is fish (`/home/linuxbrew/.linuxbrew/bin/fish`). Any command you hand me to run
must be fish-compatible.

- No bash heredocs (`-m "$(cat <<'EOF' … EOF)"`) — they break in fish.
- Multi-line commit messages: repeated `-m` flags (each = a paragraph), or write the message
  to a file and use `-F msg.txt`.
- Env vars: `set -gx VAR value`, not `export VAR=value`.

## Git

- Commits are GPG-signed (`commit.gpgsign=true`, key `15AC8EA84FC2A5AE768FFD753CEBBA453DE5BCFD`)
  via a YubiKey smartcard. Keep `-S` explicit in commands you give me.
- Hand commit commands to **me** to run interactively rather than running them yourself —
  the card needs a PIN and a physical touch per signature (a "hanging" commit is usually the
  key waiting for a tap).
- Add `-s` (`Signed-off-by`) when the repo enforces DCO — check for
  `core.hooksPath` / `.githooks/commit-msg`. midnight-node does; not every repo does.
- Never push. Let **me** do the job.
- Prefer fixup commits.
- Always branch; never commit straight to `main`.
- Mark AI-assisted work with an `Assisted-by: AGENT:MODEL` trailer, **not** `Co-authored-by`.

## This machine

Ubuntu 24.04, aarch64 VM, accessed over SSH. Mixed linuxbrew + apt toolchains — brew usually
comes first on `PATH`.

- Rust via `rustup` in `~/.cargo/bin` (added to fish PATH with `fish_add_path -U`); toolchains
  come from each repo's `rust-toolchain.toml`.
- GPG/smartcard runs through **pcscd**, not scdaemon's internal CCID, with the brew gpg-agent
  (systemd user gpg-agent sockets are masked). If signing breaks: `gpgconf --kill scdaemon
  gpg-agent`, then check `gpg --card-status`; pcscd binds the reader reliably only on a live
  USB hotplug, so physically replug if wedged.
- pinentry is `pinentry-curses` — it can't render over a TUI (e.g. lazygit), so warm the PIN
  cache in a plain shell first.
