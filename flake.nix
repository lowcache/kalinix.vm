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

