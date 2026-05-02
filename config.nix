{ lib, cfg, ... }: lib.mkMerge [
    (lib.mkIf cfg.enableJSON {
        xdg.configFile."niri/niridrop.json".text = builtins.toJSON {
            workspace = cfg.workspace;
            windows = lib.mapAttrs (dropdown: defn: { inherit (defn) app_id cmd lazy; }) cfg.windows;
        };
    })

    (lib.mkIf cfg.bindModesIntegration {
        programs.niri.bind-modes.extraConfig = lib.mkBefore ''
            include "niridrop.kdl"
        '';
    })

    (lib.mkIf cfg.enableKDL {
        xdg.configFile."niri/niridrop.kdl".text = ''
            spawn-sh-at-startup "niridrop --init"

            workspace "${cfg.workspace}"

            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (dropdown: defn: ''
                window-rule {
                    match app-id=r#"^${defn.app_id}$"#
                    open-on-workspace "${cfg.workspace}"

                    open-floating true
                    open-focused false

                    default-column-width { proportion ${builtins.toString (builtins.elemAt defn.size 0)}; }
                    default-window-height { proportion ${builtins.toString (builtins.elemAt defn.size 1)}; }
                }
            '') cfg.windows)}
        '';
    })
]
