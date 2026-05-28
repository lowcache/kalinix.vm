{
  inputs.nixos-fhs-compat.url = "github:balsoft/nixos-fhs-compat";
  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm, ... }@inputs: {
    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };
    };

    nixosConfigurations.microvm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (microvm + "/nixos-modules/microvm/default.nix")
        ./configuration.nix
        {
          config = {
            _module.check = false; # Turn off schema checks to bypass missing options on older nixpkgs
            boot.isContainer = nixpkgs.lib.mkForce false;
            networking.useDHCP = nixpkgs.lib.mkForce false;
            microvm = {
              hypervisor = "qemu";
              shares = [{
                proto = "9p";
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/store";
              }];
              interfaces = [{
                type = "user";
                id = "eth0";
              }];
            };
          };
        }
      ];
      specialArgs = {
        inherit inputs;
        lib = nixpkgs.lib.extend (self: super: {
          nonEmptyStr = nixpkgs.lib.types.str; # Provide fallback for missing type in older nixpkgs
        });
      };
    };

    apps.x86_64-linux =
      let
        scripts = nixpkgs.legacyPackages.x86_64-linux.callPackage ./scripts { inherit self; };
      in
      {
        container = {
          type = "app";
          program = toString scripts.run-container;
        };
        microvm = {
          type = "app";
          program = "${self.nixosConfigurations.microvm.config.microvm.runner}/bin/run-microvm";
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

