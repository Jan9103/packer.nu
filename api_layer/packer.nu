# get the origin head (default) branch name
def 'gitutil default branch' [ directory: path ] {
	open $"($directory)/.git/refs/remotes/origin/HEAD" | str trim
	| parse 'ref: refs/remotes/origin/{branch}'
	| get -i branch.0  # if detached return null
}

def 'gitutil current branch' [ directory: path ] {
	open $"($directory)/.git/HEAD" | str trim
	| parse 'ref: refs/heads/{branch}'
	| get -i branch.0  # if detached return null
}

def 'gitutil auto checkout' [
	package
	quiet: bool = false
] {
	cd $package.dir
	let target_commit = (
		if $package.tag != null {
			# always update in case it changed
			^git fetch -q origin $"+refs/tags/($package.tag):refs/tags/($package.tag)"
			open ".git/refs/tags/($package.tag)" | str trim
		} else { $package.commit }
	)
	if $target_commit != null {
		if (open ".git/HEAD" | str trim) != $target_commit {
			^git fetch -q origin $target_commit
			^git checkout -q $target_commit
			if not $quiet {
				print $'"($package.name)" switched to commit "($target_commit)"'
			}
		}
	} else {
		let current_branch = (gitutil current branch $package.dir)
		let target_branch = (
			if $package.branch == null {
				gitutil default branch '.'
			} else { $package.branch }
		)
		if $target_branch != $current_branch {
			if not ($'.git/refs/heads/($target_branch)' | path exists) {
				^git fetch -q origin $target_branch
				^git branch -q $target_branch FETCH_HEAD
			}
			^git checkout -q $target_branch
			if not $quiet {
				print $'"($package.name)" switched to branch "($target_branch)"'
			}
		}
	}
}

def 'config load' [] {
	open $'($nu.history-path | path dirname)/packages.nuon'
}

# API-INTERFACE: Parse a package dnfinition from packages.nuon
# default_git_host and default_git_repo_prefix are used:
#   $'[(default_git_host)[/(default_git_repo_prefix)]/](user-input).git'
#   with 'https://github.com' and 'jan9103' the following sources point to the same target:
#   - https://github.com/jan9103/packer.nu.git
#   - jan9103/packer.nu
#   - packer.nu
export def 'config parse package' [
	package: record  # the package entry
	default_git_host: string = 'https://github.com'  # the default git-host prefix used
	default_git_repo_prefix: string = 'packer.nu'  # the default git-host url user/organisation prefix
] {
	let name = (
		$package | get -i as
		| default ($package.source | path basename)
	)
	{
		source: (
			if ($package.source | str substring 0..1) in ['~', '/', '\'] or ($package.source | str contains '://') or ($package.source =~ '^[a-zA-Z]:') {
				$package.source
			} else {
				if '/' in $package.source {
					$'($default_git_host)/($package.source).git'
				} else {
					$'($default_git_host)/($default_git_repo_prefix)/($package.source).git'
				}
			}
		)
		deactivate: ($package | get -i deactivate | default false)
		freeze: ($package | get -i freeze | default false)
		opt: ($package | get -i opt | default false)
		name: $name
		dir: (
			if ($package | get -i opt | default false) {
				$'($env.NU_PACKER_HOME)/opt/($name)'
			} else { 
				$'($env.NU_PACKER_HOME)/start/($name)'
			}
		)
		config: ($package | get -i config)
		condition: ($package | get -i condition)
		branch: ($package | get -i branch)
		commit: ($package | get -i commit)
		tag: ($package | get -i tag)
		disabled_modules: ($package | get -i disabled_modules | default [])
	}
}

# API-INTERFACE: Get packages defined in packages.nuon
export def 'config get packages' [] {
	let config = (config load)
	let default_git_host = ($config | get -i default_git_host | default 'https://github.com')
	let default_git_repo_prefix = ($config | get -i default_git_repo_prefix | default 'packer.nu')
	$config
	| get -i packages | default []
	| par-each {|package| config parse package $package $default_git_host $default_git_repo_prefix}
}

def 'meta load' [
	package  # "config get packages" object
] {
	let file = $'($package.dir)/meta.nuon'
	if ($file | path exists) {
		let git_commit = (
			if ($'($package.dir)/.git' | path exists) {
				PWD=$package.dir ^git log --oneline --no-abbrev-commit
				| lines | get -i 0 | default 'NaN'
			} else {'NaN'}
		)
		open $file
		| upsert current_git_commit $git_commit
	}
}

def nu_version [] {
	nu --version
	| str trim
	| split row '.'
	| each {|i| $i | into int}
}

def packer_version [] {
	open $'($env.NU_PACKER_HOME)/start/packer.nu/meta.nuon'
	| get -i version | default [0 0 0]
}

def version_comparison [
	version_a #: list<int> # [mayor minor patch]
	version_b #: list<int> # [mayor minor patch]
] {
	if $version_a.0 > $version_b.0 {'>'
	} else if $version_a.0 < $version_b.0 {'<'
	} else {
		if $version_a.1 > $version_b.1 {'>'
		} else if $version_a.1 < $version_b.1 {'<'
		} else { '==' }
	}
}

def nu_escape_string [text: string] {
	$text | str replace '[^a-zA-Z0-9]' '_'
}

# check if a package is compatible with the current install
def is_package_compatible [
	package
	nu_version
	packer_version
] {
	if ($package.meta | get -i version) == null {
		print $"(ansi red)Invalid package: ($package.name) \(missing or broken meta.nuon).(ansi reset)"
		return false
	}
	let min_nu_version = ($package.meta | get -i min_nu_version | default [0 0 0])
	let max_nu_version = ($package.meta | get -i max_nu_version | default [9999 0 0])
	let min_packer_version = ($package.meta | get -i min_packer_version | default [0 0 0])
	let max_packer_version = ($package.meta | get -i max_packer_version | default [9999 0 0])

	let result = ([
		($package.dir | path exists)  # filter not installed ones
		# filter by min and max version
		((version_comparison $nu_version $min_nu_version) != '<')
		((version_comparison $nu_version $max_nu_version) != '>')
		((version_comparison $packer_version $min_packer_version) != '<')
		((version_comparison $packer_version $max_packer_version) != '>')
	] | all {|i| $i})
	if not $result { print $"(ansi white_dimmed)Skipped: ($package.name) \(incompatible version).(ansi reset)" }
	$result
}

# Create a symlink
def symlink [
	file: string
	link: string
] {
	# Remove any existing link - Just in case
	if ($link | path exists) { rm $link }

	# Create the link - OS specific
	if ($nu.os-info.family == 'windows') {
		# Windows
		# Path strings require additional sanitization for mklink
		^mklink /D $'"($link | path expand | str replace '/' '\' --all)"' $'"($file | path expand | str replace '/' '\' --all)"' #"
	} else {
		# Linux/Mac/BSD
		^ln -s ($file | path expand) ($link | path expand)
	}
}

# (re-)generate the init-system
# is automatically executed after install and update
export def compile [] {
	print 'Compiling init-system'  #' # <- fix TS syntax hightlight
	let nu_version = (nu_version)
	let packer_version = (packer_version)
	let ignore_compatibility = (config load | get -i ignore_compatibility | default false)
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition == null
		| par-each {|package|
			$package
			| insert meta {||
				let tmp = (meta load $package)
				if ($tmp | describe | str starts-with "record") {$tmp
				} else {null}
			}
		}
		| filter {|package|
			(
				$ignore_compatibility
				or (is_package_compatible $package $nu_version $packer_version)
			)
		}
	)
	generate_init_file $packages $'($env.NU_PACKER_HOME)/packer_packages.nu'
}

# not meant to be manually executed.
# used to generate the init-system conditional packages
export def compile_cond_init [file: path] {
	let nu_version = (nu_version)
	let packer_version = (packer_version)
	let ignore_compatibility = (config load | get -i ignore_compatibility | default false)
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition != null
		| par-each {|package| $package | insert meta {|| meta load $package}}
		| where {|package| (
			(
				$ignore_compatibility
				or (is_package_compatible $package $nu_version $packer_version)
			) and (
				$package.condition
				| get -i env | default {}
				| transpose k v
				| each {|i| ($env | get -i $i.k) in $i.v}
				| all {|i| $i}
			)
		)}
	)
	generate_init_file $packages $file
}

# generate a init file
# this does not filter the packages at all -> make sure the version is compatible, etc beforehand
def generate_init_file [
	packages
	init_file: path
] {
	let lib_dirs = (
		$packages
		| par-each {|i|
			let dir = $'($i.dir)/lib'
			if ($dir | path exists) {$"'($dir)'"}
		} | compact
		| str join ' '
	)
	let package_configs = (nu -c (
		$packages
		| par-each {|i|
			if $i.config != null {
				$'| upsert (nu_escape_string $i.name) ($i.config | to nuon)'
			}
		} | compact
		| prepend '{}'
		| append '| to nuon'
		| str join (char nl)
	))
	[
		'# THIS FILE IS GENERATED - DO NOT EDIT BY HAND'
		# env.nu files
		# TODO: @deprecated
		'export-env {' #'
		"  load-env {"
		$"    NU_LIB_DIRS: \($env | get -i NU_LIB_DIRS | default [] | append [($lib_dirs)]\)"
		$'    NU_PACKER_CFG: ($package_configs)'
		'  }'
		(
			$packages
			| par-each {|i|
				let file = $'($i.dir)/env.nu'
				if ($file | path exists) {
					$'  use ($file)'
				}
			} | compact
		)
		'}'
		# init.nu files
		(
			$packages
			| par-each {|i|
				let file = $'($i.dir)/init.nu'
				if ($file | path exists) {
					$'export use ($file) *'
				}
			} | compact
		)
		# modules defined in meta.nuon files
		(
			$packages
			| par-each {|package|
				let meta_file = $'($package.dir)/meta.nuon'
				if ($meta_file | path exists) {
					let meta = (open $meta_file)
					[(
						$meta
						| get -i modules | default []
						| where not $it in $package.disabled_modules
						| each {|module|
							$'export use ($package.dir)/($module).nu *'
						}
					), (
						$meta
						| get -i prefixed_modules | default []
						| where not $it in $package.disabled_modules
						| each {|module|
							$'export use ($package.dir)/($module).nu'
						}
					)] | flatten
				}
			} | compact | flatten
		)
	] | flatten
	| str join (char nl)
	| save -f $init_file
}

# install the packages newly added to the packages.nuon
export def install [
	--quiet(-q)
] {
	config get packages
	| par-each {|package|
		if not ($package.dir | path exists) {
			print $'Installing ($package.name)'
			if (($package.source | str substring 0..1) in ['~', '/', '\']) or ($package.source =~ '^[a-zA-Z]:') {
				if not $quiet { print '-> Linking dir' }
				if ($package.source | path exists) {	
					symlink $package.source $package.dir
				} else {
					print -e $"(ansi r)Failed to link (ansi rb)($package.source)(ansi r) due to the folder being absent(ansi reset)"
				}
			} else {
				if not $quiet { print '-> Downloading' }
				^git clone --depth 1 --no-single-branch $package.source $package.dir
				gitutil auto checkout $package $quiet
			}
			if ($'($package.dir)/post_install.nu' | path exists) {
				print $'-> Running ($package.name) post install'
				nu $'($package.dir)/post_install.nu'
			}
		} # end: if not dir exists
	} # end: looping over packages
	compile  # TODO: deactivate via config
}

# update installed packages
export def update [
	--quiet(-q)
] {
	# local repos are symlinks -> not updated
	# manually added dirs dont have '.git/' -> not updated
	if not $quiet { print 'Updating packages…' }
	let header_color = ($env | get -i config.color_config.header | default green_bold)
	config get packages
	| where freeze == false
	| par-each {|package|
		mut update_info = [$'(ansi $header_color)($package.name)(ansi reset)']
		# update git
		if ($'($package.dir)/.git' | path exists) and (($package.dir | path type) == 'dir') {
			cd $package.dir
			gitutil auto checkout $package $quiet
			let old_head = (^git rev-parse HEAD)
			^git pull -q --ff-only --rebase=false
			let new_head = (^git rev-parse HEAD)
			if $old_head != $new_head {
				$update_info = ($update_info | append (^git log --oneline --color --decorate=off $'($old_head)..HEAD'))
			}
		}
		# update script
		let meta = (meta load $package)
		if ($meta.update_script? != null) {
			PWD=$package.dir ^nu $'($package.dir)/($meta.update_script)'
			$update_info = ($update_info | append 'Ran update script')
		}
		# show update info
		if not $quiet and ($update_info | len) > 1 {
			print ($update_info | str join "\n")
		}
	}
	compile  # TODO: deactivate via config
}

export def debuginfo [
	package_name: string = ''
] {
	let packages = (config get packages)
	let packer_meta = (meta load (
		$packages
		| where name == 'packer.nu' | get -i 0 | default {}
	))
	print $'Nu version: (nu --version | str trim)'
	print $'OS: ($nu.os-info.name)'
	print $'Packer version: ($packer_meta | get -i version | default "?")'
	print ''

	if $package_name != '' {
		let package = (
			config get packages
			| where source =~ $package_name
			| get -i 0
		)
		if $package == null {
			print -e $'Unable to find package "($package_name)"'
		} else {
			print $package_name
			print $'($package)'
			let meta = (meta load $package)
			if $meta != null {
				print $'version: ($meta | get -i version | default "?")'
				print $'git-commit: ($meta | get -i current_git_commit)'
			}
		}
	}
}

# get the status of packer.nu
export def status [] {
	if 'packer_api' in (overlay list) {
		print $'(ansi c)API-Layer: (ansi g)loaded'
	} else {
		print $'(ansi c)API-Layer: (ansi rb)not loaded'
		print $'  (ansi c)reload: (ansi ligr)overlay use ($env.NU_PACKER_HOME)/start/packer.nu/api_layer/packer_api.nu'
	}
	if 'packer_packages' in (overlay list) {
		print $'(ansi c)Packages: (ansi g)loaded'
	} else {
		print $'(ansi c)Packages: (ansi rb)not loaded'
		print $'  (ansi c)reload: (ansi ligr)overlay use ($env.NU_PACKER_HOME)/packer_packages.nu'
	}
	print $'(ansi reset)'
}

# delete unused packages
export def clean [] {
	let used = (config get packages).name

	for name in (ls -s $'($env.NU_PACKER_HOME)/start').name {
		if not $name in $used {
			print $'"($name)" is unused.'
			rm -rpI $'($env.NU_PACKER_HOME)/start/($name)'
		}
	}
	return
}

# manual pages
# export def man [
# 	page: string
# ] {
# 	let dirs = (
# 		config get packages
# 		| each {|i| $'($i)/doc'}
# 		| where ($it | path exists)
# 	)
# 	let results = (
# 		$dirs
# 		| par-each {|dir|
# 			ls $dir
# 			| where ($it.name | path basename) == $'($page).md'
# 		}
# 	)
# }
