# Architectural Decisions (`memory/decisions.md`)

Canonical design decisions for the **kalinix** pentesting MicroVM. Read before
changing any `.nix`.

---

## 1. MicroVM-only runtime

* **Decision (2026-06-02):** Dropped the original `systemd-nspawn` container
  profile; the MicroVM is the only runtime.
* **Why:** The container dragged in the entire FHS/LSB stack (`nixos-fhs-compat`
  input + `lsb.nix`) and a privileged host-side launcher (`scripts/run-container`:
  host `socat` listeners, raw `iptables` INPUT rules, `$HOME` rbind mount) — the
  repo's only `sudo`/attack surface. The MicroVM already force-disabled FHS/LSB
  and never used any of it, so it was dead weight. The original idea (balsoft/
  kalinix) is preserved; the dangerous implementation is gone. Attribution kept.
* **Consequence:** No global FHS/foreign-binary support. If a foreign ELF/.deb
  ever needs to run *in the guest*, use a per-tool `buildFHSEnv` wrapper, not a
  system-wide LSB module (that module broke the fast boot — see history).

## 2. Track nixos-unstable

* **Decision (2026-06-02):** `inputs.nixpkgs.url = nixos-unstable` (was pinned to
  the frozen `d233902`).
* **Why:** "Bleeding edge" requires it; pentest tooling (ProjectDiscovery,
  nuclei-templates, caido) moves weekly. Unstable also dropped the need for the
  `--extra-deprecated-features` flags, so launch is a bare `nix run .#microvm`.
* **Bonus:** unstable currently resolves to `331800d` — the same rev the host
  runs — so the VM shares the host `/nix/store` instead of building a divergent
  closure. This alignment is incidental and will drift; revisit if footprint
  matters (see todo).

## 3. Way-B GUI posture (headless VM, host drives UI)

* **Decision (2026-06-02):** Prefer tools with a daemon/API/web/client-server
  split so the heavy process stays headless in the VM and the host browser/client
  connects over `microvm.forwardPorts` (SLiRP hostfwd). All forwards bind
  `127.0.0.1` only — no LAN exposure (the lesson the old container hardening was
  fighting). `waypipe` X11/Wayland is the **Way-A fallback** for GUI-only
  binaries (Ghidra, Cutter, Wireshark, Burp Community).
* **Port map (flake.nix):** 8080 ZAP daemon · 8081 mitmweb · 8443 caido-cli ·
  8888 BloodHound CE · 7474 neo4j. Guest services must bind `0.0.0.0` to be
  reachable through the forward.

## 4. Tool selection rules

* `caido-cli` (headless server), not `caido-desktop`.
* `netexec` (nxc), not the unmaintained `crackmapexec`.
* `foundry` manages solc versions via svm, so no `solc-select` (kept plain
  `solc`); tunneling `chisel` is given `lib.hiPrio` over foundry's Solidity REPL.
* `nixpkgs.config.allowUnfree = true` (configuration.nix) covers `burpsuite`,
  `caido-cli`, `ghidra-bin`, `wpscan`.
