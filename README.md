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

### planned features

- don't blindly trust the registry file: check that any dropdown we work with is in fact currently open, to prevent breakage when dropdown windows are closed without our knowledge.

## Usage

### dropdown management
#### niridrop \[name]
toggle the visibility of the dropdown with the specified name; if no name is passed, toggle visibility of last shown dropdown (note that niridrop will automatically spawn the dropdown window if it isn't currently open)

#### niridrop \[name] --show|-s
show the dropdown if it is currently hidden, otherwise do nothing

#### niridrop \[name] --hide|-h
hide the dropdown if it is currently shown, otherwise do nothing

#### niridrop \[name] --forget|-f
the forget option is compatible with all of the above; it prevents the tool from saving this dropdown as the last open one (useful if a script wants to use `niridrop` to show its ui but doesn't want to otherwise interfere with the user's dropdown workflow)

### state management
#### niridrop --init|-i
clear all info about currently open windows and last opened window; should be called at niri startup to prevent usage of stale data

#### niridrop --kill|-k
kill all currently open windows (visible or not)

#### niridrop --dump|-d
dump info about currently open windows & last opened window

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
