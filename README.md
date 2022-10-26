# Packer.nu

A [packer.nvim][] inspired package-manager for [NuShell][].

This is a early stage of this project. Please expect:
- bugs
- changes in the API from time to time, which might require a few manual fix-steps
- **no** windows or mac support (for now)

A few recommendations:
- read the changelog before you run `packer update`
- don't close the shell after a update until you verified new shells aren't broken
- have a method of opening a bash or something to fix things
- don't update nu to a new version until `packer.nu` officially supports it
	- make sure the plugins you use also support the new version
	- run `packer update` after a nu update
- create a github issue if you encounter a issue

Supported nu-versions:
- `0.68.1` - `0.70.0`
- not all plugins support all versions
- it is recommended to use the latest supported version (which also supports your plugins)

## Features

- [x] Install and Update packages from local or git
	- [x] post-install scripts
- [x] Load packages
	- [x] Conditional (for example: only in a certain terminal)
	- [x] only load if the package supports the nu version
	- [ ] only load if the package supports the packer.nu version
- [ ] A API-Layer for packages to ease development
	- [ ] parsed versions of commands
		- [x] rg
	- [x] `$env.config` access management to prevent breaking other packages
		- [x] for hooks
	- [x] unified program arguments
		- [x] `downloader` (curl, wget, aria2c, axel, etc)
		- [x] `editor` (vim, emacs, nano, etc)
- [x] debug-information command to help with remote-debugging of packages
- [x] allow packages to add files to the `$env.NU_LIB_DIRS`
- [ ] allow packages to add files to the `$env.PATH`
- [ ] package manpages
- [ ] optional packages (load via command)
- [ ] bootstrap
- [ ] auto delete files of uninstalled packages

## Installation and Usage

Described in the Wiki.

## Examples for available packages:

- [inpw][]: lets you install packer.nu packages via commands instead of editing the `packages.nuon`
- [kitty][]: automatically makes use of the kitty-terminals functionality
- [pueue][]: adds background threads (jobs) to Nu (using pueue)
- [python][]: implements python-venvs for nu and overall improves interaction with python
- [starship][]: loads the starship prompt
- [zoxide][]: loads zoxide (a smarter version of `cd`) into nu
- [make][]: tab complete for make files
- [tmux_autoattach][]: automatically attach tmux.


[packer.nvim]: https://github.com/wbthomason/packer.nvim
[NuShell]: https://github.com/nushell/nushell
[starship]: https://github.com/jan9103/nushell_starship
[zoxide]: https://github.com/jan9103/nushell_zoxide
[inpw]: https://github.com/jan9103/nushell_inpw
[kitty]: https://github.com/jan9103/nushell_kitty
[pueue]: https://github.com/jan9103/nushell_pueue
[python]: https://github.com/jan9103/nushell_python
[make]: https://github.com/jan9103/nushell_make
[tmux_autoattach]: https://github.com/jan9103/nushell_tmux_autoattach
