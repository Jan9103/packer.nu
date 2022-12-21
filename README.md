# Packer.nu

A [packer.nvim][] inspired package-manager for [NuShell][].

Newest officially supported NuShell version: `0.73.x`

Due to breaking changes to `all` in `nu v0.73` older versions are
no longer supported by `packer.nu v0.3.0`.

## The issue this tries to solve:

Currently a nushell config is almost always a giant, unstructured
mess of outdated tab-completion snippets from many sources.

Since vim package managers managed to solve this issue within vim
fairly well and many people are already used to it this project
is heavily inspired by a really good vim package manager: [packer.nvim][].

A few examples for already existing packages:
- Auto attaching TMUX sessions
- Background threads with pueue
- Fixes for (partially) broken things, such as StreamPager
- Parsers for command outputs, such as pylint and docker
- Prompts, such as starship
- Python virtual environments
- Quick navigation utilities
- Tab completion for makefiles, shh, neovim, etc

## Installation

| :exclamation: Important notes |
| :---------------------------- |
| This project is currently in a fairly early stage and therefore probably contains a lot of bugs. |
| Currently only GNU/Linux is officially supported (the `scope` section contains more details) |

1. Open a NuShell instance
2. run `nu -c (fetch https://raw.githubusercontent.com/jan9103/packer.nu/master/install.nu)`
3. Reopen NuShell

## Basic Usage

| Note |
| :--- |
| You can use the inpw plugin ([GitHub][inpw GitHub], [CodeBerg][inpw CodeBerg]) as a alternative interface in case you prefer a apt-like interface with repositories |
| A full documentation of the usage can be found in the wiki ([GitHub][wiki GitHub], [CodeBerg][wiki CodeBerg]). |

You can specify which packages you want to use in the `packages.nuon`, which is located in your
nushell config directory (on linux: `~/.config/nushell/packages.nuon`).
The file is in the nuon file-format (in case you dont know it: json is valid nuon) and
inspired by [packer.nvim][]'s syntax.
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

After configuring your `packages.nuon` you can install the newly added packages with `packer install`
within nushell.

You can update the plugins with `packer update`.

### Updating with packer installed

Updating NuShell should only be done after checking if the new version is already supported by packer and the plugins you use.  
Packer usually supports new nushell versions within a week after their release.

If your nushell version is outdated you should not install new packages or run the update command,
since its currently not possible to select which package version should be used and a new package
version might not support your nushell version.

If a package does not support your installed packer or nushell version it will be deactivated
during the (next) update or install (or `packer compile`).

## Scope (aka Goals and Non-Goals)

**OS Support:** The primary target is GNU/Linux. If someone is interested they can create a MR adding support for something else, but i won't maintain the support since i only use Linux myself.

**Nu Version Support:** The goal is to support the 2 latest versions (if 0.72.1 is the latest this tries to be compatible with 0.72.x and 0.71.x).

**API layer scope:** The API layer is supposed to ease working with common interfaces, but should stay small in scope. The `lib` directory function can be used to write libraries for packer.

**Interface:** The inteface is supposed to stay as a config file with a few simple commands to update. A full CLI is implemented in the inpw plugin ([GitHub][inpw GitHub], [CodeBerg][inpw CodeBerg]).


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

