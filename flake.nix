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

    prismlauncher = {
      url = "github:prismlauncher/prismlauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix/23.05";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

    outputs = { nixpkgs, home-manager, hyprland, prismlauncher, helix, rust-overlay, ...}:
    let
      system = "x86_64-linux";

      tokyonight-gtk-overlay = final: prev: {
        tokyonight-gtk = prev.callPackage ./packages/tokyonight { };
      };

      ytdlp-gui-overlay = final: prev: {
        ytdlp-gui = prev.callPackage ./packages/ytdlp-gui { };
      };

      evremap-overlay = final: prev: {
        evremap = prev.callPackage ./packages/evremap { };
      };

      webcord-overlay = final: prev: {
        webcord = prev.callPackage ./packages/webcord { };
      };

      insomnia-overlay = final: prev: {
        insomnia = prev.callPackage ./packages/insomnia { };
      };

      nerdfonts-overlay = final: prev: {
        nerdfonts = prev.callPackage ./packages/nerdfonts { };
      };

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          # FIXME: remove after it gets fixed
          nerdfonts-overlay

          rust-overlay.overlays.default
          # helix.overlays.default
          prismlauncher.overlays.default
          (insomnia-overlay)
          (import ./overlays/mpvpaper.nix)
          (tokyonight-gtk-overlay)
          (ytdlp-gui-overlay)
          (evremap-overlay)
          (webcord-overlay)
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
              home-manager.extraSpecialArgs = { inherit helix; };
            }
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
