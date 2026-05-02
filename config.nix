{ lib, cfg, ... }: lib.mkMerge [
    (lib.mkIf cfg.enableJSON {
        xdg.configFile."niridrop/config.json".text = builtins.toJSON (
            lib.mapAttrs (dropdown: defn: { inherit (defn) app_id cmd; }) cfg.dropdowns
        );
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
            '') cfg.dropdowns)}
        '';
    })
]
