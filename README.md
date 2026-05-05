# niridrop

A tool to show & hide dropdown windows in niri.

- [usage](#usage), [configuration](#configuration), [installation](#installation)

### alternatives

- [ndrop](https://github.com/Schweber/ndrop/tree/main)
- [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad)
- [rochacbruno's gist](https://gist.github.com/rochacbruno/135eebb88f887fdc45210e466ad13bc7)

I wrote niridrop because:
1. I prefer to define dropdowns in a config file rather than pass long arguments every time I call the tool.
2. I wanted the tool to keep track of the last shown dropdown and be able to show/hide it.
3. I wanted to have a cli option `--show` that prevents the tool from hiding the specified window if it's already open (and analogously, `--hide`)

As far as I could tell none of the available alternatives satisfy these 3 desires.

## Usage

### dropdown management
``` sh
niridrop [name] [--show|--hide] [--forget]
```
If *name* is given, operates on the dropdown window with that name, otherwise operates on the last opened one.

If *show* or *hide* are passed, only completes actions that would result in the specified window being shown/hidden.

If *forget* is passed, doesn't save this dropdown as the last opened one (useful to show a ui without interfering with the user's dropdown workflow)

### state management
``` sh
niridrop [--init|--kill|--dump]
```

If *init* is passed, forget all info about currently open windows, and spawn all non-lazy dropdown windows (should be called at niri startup).

If *kill* is passed, close all currently open dropdown windows (visible or not)

If *dump* is passed, dump info about all currently open windows & last opened window.

## Configuration

Niridrop requires a `niridrop.json` config file as well as some options to be set in niri's `config.kdl`. You can do this manually or use the [home manager module](#home-manager-module).

### niridrop

The file `$XDG_CONFIG_HOME/niri/niridrop.json` should contain an attrset of all dropdown windows, along with the name of the workspace they should reside in when hidden. The lazy key determines if the window spawns when `--init` is called or when it is first shown.
``` json
{
  "workspace": "dropdown",
  "windows": {
    "term": {
      "app_id": "dropdown-term",
      "cmd": "kitty --class dropdown-term",
      "lazy": false
    },
    "qalc": {
      "app_id": "dropdown-qalc",
      "cmd": "kitty --class dropdown-qalc qalc",
      "lazy": true
    }
  }
}
```

### niri configuration

In order for niridrop to work properly, you need to set some niri settings. Declare the named workspace for the dropdown windows, and create window rules to send the windows to this workspace as well as make them spawn floating and unfocused. You may also specify their size here. Finally, call `niridrop --init` on startup. Add something like this to your `config.kdl`:
``` kdl
spawn-sh-at-startup "niridrop --init"

workspace "dropdown"

window-rule {
    match app-id=r#"^dropdown-$"#
    open-on-workspace "dropdown"

    open-floating true
    open-focused false

    default-column-width { proportion 0.75; }
    default-window-height { proportion 0.75; }
}
```

### home manager module

This flake exposes a home-manager module that can create all of the necessary configuration files. Import the module and set it up as below.

Note that the module will populate `niridrop.kdl`, but you must include the file yourself. Alternatively, if you use [niri-bind-modes](https://github.com/lifantsev/niri-bind-modes) you may enable `...niri.niridrop.bindModesIntegration = true`. This will use bind-modes' [extraConfig option](https://github.com/lifantsev/niri-bind-modes/blob/main/CONFIGURING.md#extraconfig) to include `niridrop.kdl`.
``` nix
# flake.nix
inputs.niridrop.url = "github:lifantsev/niridrop";

# home.nix
imports = [ inputs.niridrop.homeManagerModules.default ];

programs.niri.niridrop = {
    enableJSON = true; # whether to create niridrop.json
    enableKDL = true; # whether to create niridrop.kdl
    bindModesIntegration = true; # if you use niri-bind-modes, enable this to automatically include `niridrop.kdl` from inside `config.kdl`

    defaultSize = [ 0.6 0.6 ]; # this defaults to [ 0.75 0.75 ] if not set

    windows = {
        term = {
            app_id = "dropdown-term";
            cmd = "kitty --class dropdown-term";
            size = [ 0.6 0.3 ]; # you can override the default size
            lazy = true; # defaults to false if not set
        };

        qalc = {
            app_id = "dropdown-qalc";
            cmd = "kitty --class dropdown-qalc qalc";
        };
    };
};
```

## Installation

### flake

If you are a nix flake user, add a flake input and import the nixos module.
``` nix
# flake.nix
inputs.niridrop.url = "github:lifantsev/niridrop";

# configuration.nix
imports = [ inputs.niridrop.nixosModules.default ]; # this will also add pkgs.niridrop using an overlay

# alternatively, install the package manually
environment.systemPackages = [ inputs.niridrop.packages.${system}.default ];
```

### other

If you are not a nix user, you can download the [shellscript](https://github.com/lifantsev/niridrop/blob/main/niridrop.sh), add a shebang, and install it however you prefer (maybe put it in ~/.local/bin or create an alias).

Note that the script optionally depends on [lg](https://github.com/lifantsev/lg). If you don't want to install it, just use `sed -i '/ *lg / d' niridrop.sh` to remove all calls to it from the script.
