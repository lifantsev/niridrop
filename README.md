# niridrop

A tool to show & hide dropdown windows in niri, and a homemanager module to configure said tool.

- [usage](##Usage), [configuration](##Configuration), [installation](##Installation)

### alternatives

- [ndrop](https://github.com/Schweber/ndrop/tree/main)
- [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad)
- [rochacbruno's gist](https://gist.github.com/rochacbruno/135eebb88f887fdc45210e466ad13bc7)

I wrote `niridrop` because:
1. I prefer to define dropdowns in a config file rather than pass long arguments every time I call the tool.
2. I wanted the tool to keep track of the last shown dropdown and be able to show/hide it.
3. I wanted to have a cli option `--show` that prevents the tool from hiding the specified window if it's already open (and analogously, `--hide`)

As far as I could tell none of the available alternatives satisfy these 3 desires.

## Usage

#### niridrop --init
clear the file that keeps track of currently open dropdown windows & the file tracking the last open window.

#### niridrop --kill
kill all currently open dropdown windows (visible or not) and clear the file keeping track of them.

#### niridrop <name?>
show the dropdown named `<name>` if currently hidden, and hide it if currently shown. if no argument is passed, operates on the last opened dropdown.

## Configuration

### niridrop

what to put into niridrop.json and what it does

### niri configuration

what options have to be set in niri's config.kdl

### flake

explain how the homemanager module can do all of that automatically

## Installation

### flake

explain how to install the package using the flake

### other

explain how to install on non-nix systems
