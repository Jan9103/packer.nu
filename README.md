# Deprecation notice

## What does deprecated mean here?

I will for the forseeable future keep this compatible with new nu versions, but
* i wont add new features / packages.
* when a alternative has properly matured i will archive this.
* im no longer using it myself and therefore might not notice new bugs.


## What now?

Suggestion:

* New users: use a active alternative.  
* Old users: if packer does everything you need keep using it until it breaks or something else matures.  
* Package devs: use the [nupm][] format.


## Alternatives

| Name        | Status         | nu versions     | Author       | Package format(s) | Written in  |
| ----------- | -------------- | --------------- | ------------ | ----------------- | ----------- |
| `packer.nu` | `deprecated`   | latest + recent | jan9103      | `packer.nu`       | `nu`-script |
| [nupm][]    | `experimental` | nightly         | nushell-team | `nupm`            | `nu`-script |
| [numng][]   | `experimental` | latest + recent | jan9103      | `numng`, `packer.nu` (partial), `nupm` (partial) | `python` |
| [nuun][]    | `test bed` / `abandoned` | ?     | kubouch      | `nuun`            | `nu`-script |
| [NuPac][]   | `archived`     | `0.73.0`        | skelly37     | `nupac`           | `nu`-script |


---


# Packer.nu (Main README)

A [packer.nvim][] inspired package-manager for [NuShell][].

Newest officially supported NuShell version: `0.103.x`

| :information_source: Please ensure to update nushell **after** packer supports the new version |
| :--- |


## Installation

Notice: It works on GNU/Linux and Windows, but macos and bsd are probably similar enough to work as well.

Install command:
`nu -c (http get https://raw.githubusercontent.com/jan9103/packer.nu/master/install.nu)`

You have to reopen nu afterwards.


## Basic Usage


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


## Links

- Source Code: [CodeBerg][packer.nu CodeBerg], [GitHub][packer.nu GitHub]
- The Wiki / Documentation: [CodeBerg][wiki CodeBerg], [GitHub][wiki GitHub]
- [NuShell][]
- ~~[NuPac][] (another nushell package manager)~~
- [nupm][] (nushell package manager made by the nushell dev-team)
- [numng][] (successor to packer.nu)


[packer.nvim]: https://github.com/wbthomason/packer.nvim
[NuShell]: https://github.com/nushell/nushell
[NuPac]: https://github.com/skelly37/nupac
[nupm]: https://github.com/nushell/nupm
[numng]: https://github.com/jan9103/numng
[nuun]: https://github.com/kubouch/nuun

[packer.nu GitHub]: https://github.com/jan9103/packer.nu
[packer.nu CodeBerg]: https://codeberg.org/packer.nu/packer.nu
[wiki GitHub]: https://github.com/Jan9103/packer.nu/wiki
[wiki CodeBerg]: https://codeberg.org/packer.nu/packer.nu/wiki
[inpw GitHub]: https://github.com/jan9103/nushell_inpw
[inpw CodeBerg]: https://codeberg.org/packer.nu/inpw
