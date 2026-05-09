{ nixpkgs, lg, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lga = lg.packages.${system}.lga;
    lge = lg.packages.${system}.lge;
in {
    default = pkgs.resholve.writeScriptBin "niridrop" {
        interpreter = "${pkgs.bash}/bin/bash";
        execer = [
            "cannot:${pkgs.niri}/bin/niri"
            "cannot:${lga}/bin/lga"
            "cannot:${lge}/bin/lge"
        ];

        inputs = [
            lga lge
            pkgs.coreutils
            pkgs.niri
            pkgs.jq
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
        ];
    } (builtins.readFile ./niridrop.sh);
}
