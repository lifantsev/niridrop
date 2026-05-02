# niridrop

This flake contains a script to show & hide dropdown windows in niri, and a homemanager module to configure said script.

- [usage](##Usage)
- [configuration](##Configuration)
- [installation](##Installation)

### alternatives

- [ndrop](https://github.com/Schweber/ndrop/tree/main)
- [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad)
- [rochacbruno's gist](https://gist.github.com/rochacbruno/135eebb88f887fdc45210e466ad13bc7)

I wrote `niridrop` because:
1. I prefer to define dropdowns in a config file rather than pass long arguments every time.
2. I wanted the tool to keep track of and be able to show/hide the last shown dropdown.
3. I wanted to have a cli option `--show` that prevents the tool from hiding the specified window if it's already open (and `--hide` with inverse functionality)

As far as I could tell none of the available alternatives have these 3 features.

## Usage

demonstrate all cli options

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
