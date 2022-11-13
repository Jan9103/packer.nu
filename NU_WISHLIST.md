# My NuShell feature wishlist

## Fix extern within modules

1. create `git.nu`
2. write `export extern fetch [repository: string, --all]` into it
3. `use git.nu`
4. type `git fetch --` and then tab -> it will complete `--all`
5. press return -> `External command failed`, `did you mean 'fetch'?`
6. `help commands` lists `fetch` as command, but not `git fetch`

## Add a output parser to `extern`

Right now i have to write wrapper script for basically everything
if i want to use the output (or always write a parse on the fly).

```
extern 'cargo search' [
	query: string
	--limit: int
] {|output|
	$output | lines
	| parse -r '(?P<name>.+) = "(?P<version>.+)" *#? ?(?P<description>.+)?'
}
```

other examples:
- `docker ps`
- `ldap-search`

## While (and break)

```
while true {
	let input = (input '> ')
	if $input == 'exit' {break}
	# …
}
```

## Try Except

```
try {
	ls */foo.nu
} except {|exception|
	print 'no foo.nu found'
	[]
} | each {|i| mv $i.name .}
```

in this case `ls -i` (similar to `get -i`) would also work, but
a try except would solve many cases.

## A integrated version of fzf

maybe as a plugin, but i cant figure out how to write working plugins

fzf is a really cool tool for tui applications, but it could really profit from a better integration:
- pass extra (not shown) info with the options, which can be used later or in the preview
- actual nu code block for `--preview` and not a string in a string..
- working `esc` key within nushell
- use the colorscheme, borderstyle, and edit mode (vim/ emacs)
