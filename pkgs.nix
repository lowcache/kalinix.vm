# Curated arsenal for the kalinix MicroVM. Tracks nixos-unstable.
# Posture: prefer tools with a daemon/API/web/client-server split so the heavy
# process stays headless in the VM and the host drives the UI over a forwarded
# port (Way B). waypipe is the fallback for GUI-only binaries.

pkgs: with pkgs; [
  ### Shell / general ###
  bat
  ripgrep
  fd
  jq
  fzf
  ranger
  git
  tmux
  socat
  proxychains-ng

  ### Web app testing ###
  zap              # OWASP ZAP — run headless: `zap.sh -daemon` (+ HUD/API)
  caido-cli        # Burp alternative; headless server in VM, client on host (Way B)
  burpsuite        # Community edition (unfree, GUI/waypipe fallback)
  mitmproxy        # `mitmweb` serves a web UI on a port (Way B)
  ffuf
  feroxbuster
  gobuster
  wfuzz
  nuclei
  nuclei-templates
  katana
  sqlmap
  dalfox
  arjun
  wpscan

  ### Recon / OSINT (ProjectDiscovery pipeline + friends) ###
  subfinder
  dnsx
  httpx
  naabu
  amass
  assetfinder
  waybackurls
  gau
  gowitness
  theharvester
  dnsrecon
  sn0int
  nmap
  masscan
  rustscan

  ### Active Directory / internal network ###
  netexec          # crackmapexec successor (nxc)
  bloodhound       # CE web app (Way B: browse from host)
  bloodhound-py
  certipy
  kerbrute
  evil-winrm
  responder
  enum4linux-ng
  smbmap
  ldapdomaindump
  python3Packages.impacket
  # mitm6 — dropped: breaks on unstable's python3.13 (future-1.0.0 unsupported).
  # Re-add when nixpkgs patches it, or via a python311 override.

  ### Red-team / C2 + secrets ###
  metasploit       # metasploit-framework
  havoc            # modern C2
  villain
  (lib.hiPrio chisel)  # tunneling/pivoting; wins the `chisel` name over foundry's REPL
  ligolo-ng
  trufflehog
  gitleaks

  ### Smart-contract auditing (Web3) ###
  slither-analyzer # static analysis
  foundry          # forge / cast / anvil
  echidna          # property fuzzer
  medusa           # parallelized fuzzer
  semgrep          # SAST rules
  solc             # foundry's `forge` manages additional solc versions via svm
  vyper

  ### Reverse engineering / forensics ###
  ghidra-bin
  radare2
  cutter
  jadx
  apktool
  binwalk
  capstone
  python3Packages.distorm3
  yara
  sleuthkit
  # volatility3 — dropped: breaks on unstable's python3.13 (future-1.0.0
  # unsupported). High-value (memory forensics); re-add when nixpkgs fixes it.
  binutils
  elfutils
  patchelf
  valgrind

  ### Passwords ###
  hashcat
  hcxtools
  john
  thc-hydra
  crunch
  crowbar

  ### Sniffing / network ###
  wireshark        # wireshark-qt; or `termshark` for TUI
  termshark
  tcpdump
  bettercap
  sniffglue

  ### Wordlists ###
  seclists
  wordlists
]
