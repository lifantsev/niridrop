{ nixpkgs, lg, ... }: system: let
    pkgs = import nixpkgs { inherit system; };
    lg_pkg = lg.packages.${system}.default;
in {
    default = pkgs.resholve.writeScriptBin "niridrop" {
        interpreter = "${pkgs.bash}/bin/bash";
        execer = [
            "cannot:${pkgs.niri}/bin/niri"
            "cannot:${lg_pkg}/bin/lg"
        ];

        inputs = [
            lg_pkg
            pkgs.coreutils
            pkgs.niri
            pkgs.jq
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
        ];
    } (builtins.readFile ./niridrop.sh);

}
