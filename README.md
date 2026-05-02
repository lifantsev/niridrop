# niridrop

This flake contains a script to show & hide dropdown windows in niri, and a homemanager module to configure said script.

### alternatives

- [ndrop](https://github.com/Schweber/ndrop/tree/main)
- [niri-scratchpad](https://github.com/gvolpe/niri-scratchpad)
- [rochacbruno's gist](https://gist.github.com/rochacbruno/135eebb88f887fdc45210e466ad13bc7)

I wrote `niridrop` because:
1. I prefer to define dropdowns in a config file rather than pass long arguments every time.
2. I wanted the tool to keep track of and be able to show/hide the last shown dropdown.
3. I wanted to have a cli option `--show` that prevents the tool from hiding the specified window if it's already open (and `--hide` with inverse functionality)

As far as I could tell none of the available alternatives have these 3 features.

### toc

- [usage](##Usage)

## Usage

demonstrate all cli options

## Configuration

### Niridrop

what to put into niridrop.json and what it does

### Niri Configuration

what options have to be set in niri's config.kdl

### Flake

explain how the homemanager module can do all of that automatically

## Installation

### Flake

explain how to install the package using the flake

### Other

explain how to install on non-nix systems
