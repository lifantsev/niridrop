{
    description = "dropdown window manager for niri";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { nixpkgs, lg, ... }: let
        systems = [ "aarch64-linux" "x86_64-linux" ];
    in {
        packages = nixpkgs.lib.genAttrs systems (system: let
            pkgs = import nixpkgs { inherit system; } // {
                lg = lg.packages.${system}.default;
            };
        in {
            default = pkgs.resholve.writeScriptBin "niridrop" {
                interpreter = "${pkgs.bash}/bin/bash";
                execer = [
                    "cannot:${pkgs.niri}/bin/niri"
                    "cannot:${pkgs.lg}/bin/lg"
                ];

                inputs = [
                    pkgs.lg
                    pkgs.coreutils
                    pkgs.niri
                    pkgs.jq
                    pkgs.gnugrep
                    pkgs.gawk
                ];
            } (builtins.readFile ./niridrop.sh);
        });
    };
}
