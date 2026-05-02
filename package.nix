{ nixpkgs, lg, ... }: system: let
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

}
