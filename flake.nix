{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, hyprland, ... }:
    let
      system = "x86_64-linux";

      tokyonight-gtk-overlay = final: prev: {
        tokyonight-gtk = prev.callPackage ./packages/tokyonight {};
      };

      ytdlp-gui-overlay = final: prev: {
        ytdlp-gui = prev.callPackage ./packages/ytdlp-gui {};
      };

      helix-overlay = final: prev: {
        helix = prev.callPackage ./packages/helix {};
      };

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          (import ./overlays/discord.nix)
          (import ./overlays/insomnia.nix)
          (import ./overlays/mpvpaper.nix)
          (tokyonight-gtk-overlay)
          (ytdlp-gui-overlay)
          (helix-overlay)
        ];
      };

      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        # nixos is my hostname
        nixos = lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./system/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.salman = {
                imports = [
                  ./home.nix
                  hyprland.homeManagerModules.default
                ];
              };
            }
          ];
          # specialArgs = {};
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
