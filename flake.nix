{
    description = "dropdown window manager for niri";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

        lg.url = "github:lifantsev/lg";
        lg.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { nixpkgs, ... }@args: {
        packages = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ]
                                        (import ./package.nix args);
    };
}
