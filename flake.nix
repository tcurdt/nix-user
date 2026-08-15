{
  description = "home management for tcurdt";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nixpkgs-darwin-fish.url = "github:NixOS/nixpkgs/9b8e6819224551756919099c1fce6e347f5a3803";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      username = "tcurdt";

      # pinned-fish =
      #   final: prev:
      #   if prev.stdenv.hostPlatform.isDarwin then
      #     {
      #       fish = inputs.nixpkgs-darwin-fish.legacyPackages.${prev.stdenv.hostPlatform.system}.fish;
      #     }
      #   else
      #     { };

      systems = [
        "aarch64-darwin"
        # "x86_64-darwin"
        "x86_64-linux"
        # "aarch64-linux"
      ];

      homeDirBySystem = {
        aarch64-darwin = "/Users/${username}";
        x86_64-darwin = "/Users/${username}";
        x86_64-linux = "/home/${username}";
        aarch64-linux = "/home/${username}";
      };

      mkHome =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # overlays = [ pinned-fish ];
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            self.homeManagerModules.tcurdt
            {
              home.username = username;
              home.homeDirectory = homeDirBySystem.${system};
            }
          ];
        };

    in
    {
      homeManagerModules = {
        tcurdt =
          { ... }:
          {
            imports = [
              ./modules/common.nix
              ./modules/darwin.nix
              ./modules/linux.nix
            ];
          };
        common = import ./modules/common.nix;
        darwin = import ./modules/darwin.nix;
        linux = import ./modules/linux.nix;
      };

      nixosModules.default =
        { lib, ... }:
        {
          imports = [ home-manager.nixosModules.default ];

          home-manager.useGlobalPkgs = lib.mkDefault true;
          home-manager.useUserPackages = lib.mkDefault true;
        };

      homeConfigurations = lib.listToAttrs (
        map (system: {
          name = "${username}-${system}";
          value = mkHome system;
        }) systems
      );

      checks = lib.genAttrs systems (system: {
        home = (mkHome system).activationPackage;
      });
    };
}
