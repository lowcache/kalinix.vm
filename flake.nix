{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm, ... }@inputs: {
    nixosConfigurations.microvm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (microvm + "/nixos-modules/microvm/default.nix")
        ./configuration.nix
        {
          config = {
            microvm = {
              hypervisor = "qemu";
              shares = [{
                proto = "9p";
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              }];
              interfaces = [{
                type = "user";
                id = "eth0";
                mac = "02:00:00:00:00:01";
              }];
              # Way B: host -> guest port forwards over SLiRP user networking.
              # Run a tool headless in the VM on the guest port, then reach it from
              # the host at 127.0.0.1:<host.port>. Bound to loopback only, so nothing
              # is exposed to the LAN.
              forwardPorts = [
                { from = "host"; proto = "tcp"; host.address = "127.0.0.1"; host.port = 8080; guest.port = 8080; } # ZAP -daemon (API + HUD)
                { from = "host"; proto = "tcp"; host.address = "127.0.0.1"; host.port = 8081; guest.port = 8081; } # mitmweb
                { from = "host"; proto = "tcp"; host.address = "127.0.0.1"; host.port = 8443; guest.port = 8443; } # caido-cli server
                { from = "host"; proto = "tcp"; host.address = "127.0.0.1"; host.port = 8888; guest.port = 8888; } # BloodHound CE web UI
                { from = "host"; proto = "tcp"; host.address = "127.0.0.1"; host.port = 7474; guest.port = 7474; } # neo4j browser (BloodHound DB)
              ];
            };
          };
        }
      ];
      specialArgs = {
        inherit inputs;
      };
    };

    apps.x86_64-linux = {
      microvm = {
        type = "app";
        program = "${self.nixosConfigurations.microvm.config.microvm.runner.qemu}/bin/microvm-run";
      };
    };

    defaultPackage = builtins.mapAttrs
      (system: _:
        let
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            inherit system;
          };
        in
        pkgs.buildEnv {
          name = "pentesting-tools";
          paths = import ./pkgs.nix pkgs;
        })
      nixpkgs.legacyPackages;
  };
}

