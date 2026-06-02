# Known Mistakes and Prevention Rules (`memory/mistakes.md`)

Pitfalls hit while modernizing **kalinix**. Study before editing `.nix`.

---

## 1. nixpkgs attribute name vs package pname

* **Incident (2026-06-02):** Wrote `certipy-ad` and `ghidra` in `pkgs.nix`; the
  build failed with `undefined variable 'certipy-ad'`. The availability sweep had
  printed *pnames* (`certipy-ad`, `ghidra`) while the *attribute* names are
  `certipy` and `ghidra-bin`.
* **Prevention Rule:** A verification sweep that reports `.pname`/`.name` shows
  the package's name, NOT the attribute path. Use the attribute KEY (left column)
  in `pkgs.nix`. When unsure, test the exact attr: `nix eval <pin>#<attr>.name`.

## 2. python3.13 / `future` breakage on unstable

* **Incident (2026-06-02):** Full build aborted with `future-1.0.0 not supported
  for interpreter python3.13`. Unstable defaults to py3.13, which drops the old
  `future` compat shim; legacy Python tools break. Culprits: `mitm6`,
  `volatility3`. They are absent from `python311Packages`/`python312Packages`,
  and a `.override { python3 = python311; }` did not evaluate.
* **Prevention Rule:** When tracking unstable, a green *eval* does not guarantee a
  green *build*. Before adding a Python pentest tool, sanity-check it builds on
  the current interpreter. If a tool is `future`-bound and unfixable cheaply,
  drop it with a dated comment and re-test after a nixpkgs bump.

## 3. `allowUnfree` false-positives in standalone sweeps

* **Incident (2026-06-02):** A culprit sweep flagged `wpscan` as broken; the real
  cause was `unfreeRedistributable`. The sweep used a plain `nixpkgs` without
  `allowUnfree`, but the VM sets `nixpkgs.config.allowUnfree = true`, so wpscan
  builds fine in-VM.
* **Prevention Rule:** Reproduce the build's `allowUnfree`/config context when
  diagnosing a single package, or you will "fix" things that aren't broken.

## 4. PATH collisions in the system environment

* **Incident (2026-06-02):** buildEnv warned on colliding `/bin/chisel`
  (foundry's REPL vs the tunneling tool) and `/bin/solc` (`solc` vs
  `solc-select`). NixOS silently picked one — nondeterministic intent.
* **Prevention Rule:** Resolve name collisions explicitly: `lib.hiPrio` the tool
  that should win, or drop the redundant one. Do not rely on list order.

## 5. Background-task exit code can mislead

* **Incident (2026-06-02):** A backgrounded `nix build ... | tail` reported
  "exit 0" because the wrapper's final command (`tail`/`echo`) succeeded, while
  the actual `nix build` had failed.
* **Prevention Rule:** Read the real `BUILD EXIT: ${PIPESTATUS[0]}` line in the
  output, not just the task wrapper's exit summary.

---

## 6. Way-B host ports collided with host services

* **Incident (2026-06-02):** The VM refused to boot:
  `Could not set up host forwarding rule 'tcp:127.0.0.1:8080-:8080'`. qemu could
  not bind host `127.0.0.1:8080` because the host already runs `open-webui`
  there (and `ollama` on 11434). The build was green; only the boot-test caught
  it.
* **The Bug:** `microvm.forwardPorts` host ports were set to the same
  conventional values as the guest ports (8080/8081/…), which clash with host
  services. The `host.port` is bound on the HOST, so it must be host-unique.
* **Fix:** Host ports moved to the `1xxxx` range (18080, 18081, 18443, 18888,
  17474); guest ports kept conventional so in-VM tools still bind their defaults.
* **Prevention Rule:** `host.port != guest.port` is fine and expected. Pick host
  ports outside the host's listening set (`ss -tlnH`) — open-webui (8080) and
  ollama (11434) are already taken on this machine. Build-verification cannot
  catch a host bind conflict; only a boot-test can.
