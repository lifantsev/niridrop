{
    description = "dropdown window manager for niri";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { self, nixpkgs, ... }@args: {
        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ]
                                        (import ./package.nix args);

        nixosModules.default = { pkgs, ... }: {
            nixpkgs.overlays = [(final: prev: {
                niridrop = self.packages.${final.system}.default;
            })];

            environment.systemPackages = [ pkgs.niridrop ];
        };

        homeManagerModules.default = args: let
            args' = args // { cfg = args.config.programs.niri.niridrop; };
        in {
            options.programs.niri.niridrop = import ./options.nix args';
            config = import ./config.nix args';
        };
    };
}
