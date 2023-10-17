# Packer.nu

A [packer.nvim][] inspired package-manager for [NuShell][].

Newest officially supported NuShell version: `0.86.x`

| :information_source: Please ensure to update nushell **after** packer supports the new version |
| :--- |


## Why? What? How?

Most nushell configs without a package-manager:
- complicated and confusing
  - everything in a few files or sourced in weird ways
- half commented out
  - broken over time
  - currently not needed
- half outdated (the author updated a snippet, but no one noticed)
- missing features (to lazy to search for a working foo tab completion)

The solution: copy a method, which works: the vim package management system.  
Or to be more precise: the (at the project start) biggest system: [packer.nvim][].

### Which packages exist?

A few examples:
- Tab completion for makefiles, shh, neovim, etc
- Parsers for command outputs, such as pylint and docker
- Prompts, such as starship
- Quick navigation utilities
- Python virtual environments
- Auto attaching TMUX sessions
- Background threads with pueue

## Installation

Notice: It works on GNU/Linux and Windows, but macos and bsd are probably similar enough to work as well.

Install command:
`nu -c (http get https://raw.githubusercontent.com/jan9103/packer.nu/master/install.nu)`

You have to reopen nu afterwards.


## Basic Usage


### INPW

The INPW package adds a alternative usage based on package-repositories and commands (similar to apt, pacman, etc)

The usage and setup is explained on its [GitHub][inpw GitHub] and [CodeBerg](inpw CodeBerg) page.

### Selecting and Configuring packages

| :information_source: A full documentation of the usage can be found in the wiki ([GitHub][wiki GitHub], [CodeBerg][wiki CodeBerg]). |
| :-- |


`~/.config/nushell/packages.nuon` contains your package list and packer-configuration.  
A example config:
```
{
  packages: [
    # the config should specify packer.nu itself in order to allow automatic updates.
    {source: 'jan9103/packer.nu'}  # -> https://github.com/jan9103/packer.nu

    # any git-repository URI, which is not password protected should be supported
    {source: 'https://codeberg.org/packer.nu/bookmarks.git'}

    # you can also use local directories
    # this symlinks the directory and wont update it with `packer update`.
    {source: '~/code/my_packer_nu_plugin'}
  ]
}
```

To install new packages run `packer install`.

To update installed packages run `packer update`.


## Goals:


### Packer

- familiar [packer.nvim][] like usage
- expandable (via packages)
- maintainability between nu versions
- support for the latest version (as well as the version before)


### Package format

- easy to pick up and write new packages
- easy to write a (new) package-manager for
- easy to maintain
- version independent

## FAQ

**[Insert Operating System] has a issue?**  
Since i exclusively use linux (and android) can't properly maintain support myself.  
If you are up for it (or just a one time fix) feel free to open a MergeRequest.

**I need help with something, but don't want to open a git issue.**  
There is a Matrix channel: [#packer.nu:matrix.org](https://matrix.to/#/#packer.nu:matrix.org)

**Is it "production" ready?**  
i have been [dogfooding](https://en.wikipedia.org/wiki/Eating_your_own_dog_food) it for
quite some time now and only ever had issues during development and installation
(which should now work better with v0.4).  
Since nushell will be usable (without packages) even if packer is completely broken
and nushell itself isn't quite stable/feature complete i would argue call it stable
enough.


## Links
- Source Code: [CodeBerg][packer.nu CodeBerg], [GitHub][packer.nu GitHub]
- The Wiki / Documentation: [CodeBerg][wiki CodeBerg], [GitHub][wiki GitHub]
- Matrix channel: [#packer.nu:matrix.org](https://matrix.to/#/#packer.nu:matrix.org)
- [NuShell][]
- [NuPac][] (another nushell package manager)


[packer.nvim]: https://github.com/wbthomason/packer.nvim
[NuShell]: https://github.com/nushell/nushell
[NuPac]: https://github.com/skelly37/nupac

[packer.nu GitHub]: https://github.com/jan9103/packer.nu
[packer.nu CodeBerg]: https://codeberg.org/packer.nu/packer.nu
[wiki GitHub]: https://github.com/Jan9103/packer.nu/wiki
[wiki CodeBerg]: https://codeberg.org/packer.nu/packer.nu/wiki
[inpw GitHub]: https://github.com/jan9103/nushell_inpw
[inpw CodeBerg]: https://codeberg.org/packer.nu/inpw
