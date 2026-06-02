# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

Open loops for **kalinix**.

---

## 1. Pending verification (immediate)

* [x] **Boot-test the VM (2026-06-02).** Boots clean on kernel 6.18.33 to
  `user@kalinix:~$` autologin, no panics, all systemd targets reached. The test
  caught a host-port collision (see mistakes.md#6), now fixed.
* [ ] **Verify a forward end-to-end.** Not yet done non-interactively: start
  `zap.sh -daemon -host 0.0.0.0 -port 8080` in the guest, then `curl
  127.0.0.1:18080` from the host. Confirm the Way-B path actually carries traffic.
* [ ] **Time the boot properly.** Run `systemd-analyze` inside the guest to check
  the sub-second claim (serial-console wall-clock to login is a few seconds incl.
  SeaBIOS, which is expected and not the same metric).

## 2. Enhancements

* [ ] **Auto-start Way-B services.** Add optional systemd units so the VM boots
  straight to a live ZAP/mitmweb/Caido on the forwarded ports (bound `0.0.0.0`),
  so no manual launch is needed. This is what makes it feel like "a force."
* [ ] **Add Sliver C2.** Not in nixpkgs; wire it via its own flake input or a
  small derivation. (`havoc`/`villain`/`metasploit` cover C2 in the meantime.)
* [ ] **Re-add py3.13 casualties.** `mitm6` and `volatility3` were dropped over
  the `future`/python3.13 break (see mistakes.md#2). Re-test after nixpkgs bumps
  and restore them when they build.

## 3. Reproducibility watch

* [ ] **unstable HEAD drift.** Tracking `nixos-unstable` means `nix flake update`
  moves the pin and can re-break tools. It currently aligns with the host rev
  (`331800d`); that will drift. Decide whether to periodically pin to a known-good
  rev for reproducibility vs. always tracking HEAD.
