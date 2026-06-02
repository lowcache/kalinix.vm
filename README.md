# Kalinix MicroVM Pentesting Environment

A Nix-based pentesting environment that boots in under a second to a full toolset
inside a hermetic, hardware-accelerated QEMU MicroVM. It runs entirely in
user-space — no root, no host firewall changes, no host bind-mounts — and adds
zero extra disk footprint by sharing the host's `/nix/store` read-only.

---

## 🌟 Design

*   **Near-instant boot.** Uses `microvm.nix` with an optimized guest kernel.
*   **Zero extra disk footprint.** The host `/nix/store` is mounted read-only over
    a 9p `ro-store` share into `/nix/.ro-store`, with a writable overlay on top.
    Nothing the VM needs is duplicated on disk.
*   **Kernel isolation.** The guest runs its own Linux kernel under QEMU. Panics,
    crashes, and low-level exploits from suspect binaries stay confined to the VM.
*   **Rootless / no host mutation.** User-mode (slirp) networking means no `sudo`,
    no `iptables` rules on the host, and no host paths mounted into the guest. The
    only host-side requirement is a graphical forwarder (see GUI Forwarding).

> **Note on the removed container profile.** Earlier revisions also shipped an
> imperative `systemd-nspawn` container that started host-side `socat` listeners,
> inserted raw `iptables` rules, and bind-mounted `$HOME` into the guest. That
> path required `sudo` and was the repository's entire privileged attack surface.
> It has been removed in favor of the MicroVM, which achieves the same goal
> without touching the host. The original idea is preserved; the dangerous
> implementation is gone.

---

## 🚀 Usage

```bash
nix run .#microvm \
  --extra-experimental-features "nix-command flakes" \
  --extra-deprecated-features "url-literals" \
  --extra-deprecated-features "or-as-identifier" \
  --extra-deprecated-features "broken-string-indentation"
```

The `--extra-deprecated-features` flags are required only because this flake is
pinned to an older `nixpkgs` revision whose expressions predate some Nix/Lix
deprecations. When the pin is bumped to match the host channel, they can be
dropped.

A standalone bundle of just the tools (no VM) is also available:

```bash
nix build .#defaultPackage.x86_64-linux   # buildEnv named "pentesting-tools"
```

---

## 🖥️ GUI Forwarding

Graphical tools are forwarded to the host over the user-mode network gateway
(`10.0.2.2`):

*   **Wayland** via `waypipe`: a guest `systemd` service connects to the host on
    TCP `1337`. The guest socket `/tmp/waypipe-server.sock` is restricted to
    `user:users` (`mode=660`).
*   **X11** via `DISPLAY=<host>:0`.

Run a matching `waypipe`/X listener on the host to receive the windows.

---

## ⚖️ Attribution & Licensing

*   **Base Project:** This repository is a fork of the public NixOS pentesting
    configuration originally published by
    [balsoft/kalinix](https://github.com/balsoft/kalinix). The base project did
    not contain an explicit open-source license.
*   **Modifications & Fork Additions:** The MicroVM integration and subsequent
    changes developed in this fork are licensed under the **MIT License** (see
    [LICENSE](./LICENSE)).
*   For full details on the copyright lineage and modifications, refer to
    [COPYING](./COPYING).
