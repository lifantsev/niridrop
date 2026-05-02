{ lib, cfg, ... }: {
    enableJSON = lib.mkEnableOption "creation of niridrop.json (this will write all dropdowns along with their app_id & cmd)";

    enableKDL = lib.mkEnableOption "creation of niridrop.kdl (with window rules & workspace definition)";

    bindModesIntegration = lib.mkEnableOption "usage of the programs.niri.bind-modes.extraConfig option to automatically include `niridrop.kdl`";

    workspace = lib.mkOption {
        description = "name of the workspace to send dropdown windows to";
        type = lib.types.str;
        default = "dropdown";
        example = "scratch";
    };

    defaultSize = lib.mkOption {
        description = "default width & height (as decimals [0, 1]) for all dropdowns";
        type = lib.types.listOf lib.types.number;
        default = [ 0.75 0.75 ];
        example = [ 0.6 0.3 ];
    };

    windows = lib.mkOption {
        description = "an attrset describing all dropdown windows";
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: { options = {
            enable = lib.mkEnableOption "setup of the ${name} dropdown window";

            app_id = lib.mkOption {
                description = "the app_id that this window will have when spawned";
                type = lib.types.str;
                default = "";
                example = "dropdown";
            };

            cmd = lib.mkOption {
                description = "shell cmd to spawn the window";
                type = lib.types.str;
                default = "";
                example = "kitty --class dropdown";
            };

            size = lib.mkOption {
                description = "width & height (as decimals [0, 1]) for this dropdown window";
                type = lib.types.listOf lib.types.number;
                default = cfg.defaultSize;
                example = [ 0.6 0.3 ];
            };
        };}));
        default = {};
    };
}
