{ lib, cfg, ... }: lib.mkIf cfg.enable {
    xdg.configFile."niri/niridrop.json".text = builtins.toJSON {
        workspace = cfg.workspace;
        windows = lib.mapAttrs (dropdown: defn: { inherit (defn) app_id cmd lazy; }) cfg.windows;
    };

    programs.niri.settings = {
        spawn-at-startup = [ { argv = [ "niridrop" "--init" ];} ];

        workspaces.${cfg.workspace} = {};

        window-rules = (lib.mapAttrsToList (dropdown: defn: {
            matches = [ { app-id = "^${defn.app_id}$"; }];

            open-on-workspace = cfg.workspace;
            open-floating = true;
            open-focused = false;

            default-column-width.proportion = builtins.elemAt defn.size 0;
            default-window-height.proportion = builtins.elemAt defn.size 1;
        }) cfg.windows);
    };
}
