# get the origin head (default) branch name
def 'gitutil default branch' [ directory: path ] {
	open --raw $"($directory)/.git/refs/remotes/origin/HEAD"
	| decode 'utf-8'
	| str trim
	| parse 'ref: refs/remotes/origin/{branch}'
	| $in.branch?.0?  # if detached return null
}

def 'gitutil current branch' [ directory: path ] {
	open --raw $"($directory)/.git/HEAD"
	| decode 'utf-8'
	| str trim
	| parse 'ref: refs/heads/{branch}'
	| $in.branch?.0?  # if detached return null
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
			open --raw ".git/refs/tags/($package.tag)"
			| decode 'utf-8'
			| str trim
		} else { $package.commit }
	)
	if $target_commit != null {
		if (open --raw ".git/HEAD" | decode 'utf-8' | str trim) != $target_commit {
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
			if not ($'./.git/refs/heads/($target_branch)' | path exists) {
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
	open --raw $'($nu.history-path | path dirname)/packages.nuon'
	| decode 'utf-8'
	| from nuon
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
		$package.as?
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
		deactivate: ($package.deactivate? | default false)
		freeze: ($package.freeze? | default false)
		opt: ($package.opt? | default false)
		name: $name
		dir: (
			if ($package.opt? | default false) {
				$'($env.NU_PACKER_HOME)/opt/($name)'
			} else { 
				$'($env.NU_PACKER_HOME)/start/($name)'
			}
		)
		config: $package.config?
		condition: $package.condition?
		branch: $package.branch?
		commit: $package.commit?
		tag: $package.tag?
		disabled_modules: ($package.disabled_modules? | default [])
	}
}

# API-INTERFACE: Get packages defined in packages.nuon
export def 'config get packages' [] {
	let config = (config load)
	let default_git_host = ($config.default_git_host? | default 'https://github.com')
	let default_git_repo_prefix = ($config.default_git_repo_prefix? | default 'packer.nu')
	$config.packages? | default []
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
				| lines | $in.0? | default 'NaN'
			} else {'NaN'}
		)
		open --raw $file
		| decode 'utf-8'
		| from nuon
		| upsert current_git_commit $git_commit
	}
}

def nu_version [] {
	^$nu.current-exe --version
	| decode 'utf-8'
	| str trim
	| split row '.'
	| each {|i| $i | into int}
}

def packer_version [] {
	open --raw $'($env.NU_PACKER_HOME)/start/packer.nu/meta.nuon'
	| decode 'utf-8'
	| from nuon
	| $in.version?
	| default [0 0 0]
}

def version_comparison [
	version_a #: list<int> # [major minor patch]
	version_b #: list<int> # [major minor patch]
] {
	if $version_a.0 > $version_b.0 {
		'>'
	} else if $version_a.0 < $version_b.0 {
		'<'
	} else if $version_a.1 > $version_b.1 {
		'>'
	} else if $version_a.1 < $version_b.1 {
		'<'
	} else {
		'=='
	}
}

def nu_escape_string [text: string] {
	$text | str replace --all --regex '[^a-zA-Z0-9]' '_'
}

# check if a package is compatible with the current install
def is_package_compatible [
	package
	nu_version
	packer_version
] {
	if $package.meta.version? == null {
		print $"(ansi red)Invalid package: ($package.name) \(missing or broken meta.nuon).(ansi reset)"
		return false
	}
	let min_nu_version = ($package.meta.min_nu_version? | default [0 0 0])
	let max_nu_version = ($package.meta.max_nu_version? | default [9999 0 0])
	let min_packer_version = ($package.meta.min_packer_version? | default [0 0 0])
	let max_packer_version = ($package.meta.max_packer_version? | default [9999 0 0])

	let result = ([
		($package.dir | path exists)  # filter not installed ones
		# filter by min and max version
		((version_comparison $nu_version $min_nu_version) != '<')
		((version_comparison $nu_version $max_nu_version) != '>')
		((version_comparison $packer_version $min_packer_version) != '<')
		((version_comparison $packer_version $max_packer_version) != '>')
	] | all {|i| $i})
	if not $result {
		print $"(ansi white_dimmed)Skipped: ($package.name) \(incompatible version).(ansi reset)"
	}
	$result
}

# Create a symlink
def symlink [
	file: string
	link: string
] {
	# Remove any existing link - Just in case
	if ($link | path exists) {
		rm $link
	}

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
	let ignore_compatibility = (config load | $in.ignore_compatibility? | default false)
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition == null
		| par-each {|package|
			$package
			| insert meta {||
				let tmp = (meta load $package)
				if ($tmp | describe | str starts-with "record") {
					$tmp
				} else {
					null
				}
			}
		}
		| where (
			$ignore_compatibility
			or (is_package_compatible $it $nu_version $packer_version)
		)
	)
	generate_init_file $packages $'($env.NU_PACKER_HOME)/packer_packages.nu'
}

# not meant to be manually executed.
# used to generate the init-system conditional packages
export def compile_cond_init [file: path] {
	let nu_version = (nu_version)
	let packer_version = (packer_version)
	let ignore_compatibility = (config load | $in.ignore_compatibility? | default false)
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition != null
		| par-each {|package|
			$package
			| insert meta {||
				meta load $package
			}
		}
		| where {|package| (
			(
				$ignore_compatibility
				or (is_package_compatible $package $nu_version $packer_version)
			) and (
				$package.condition
				| $in.env?
				| if $in == null { {} } else { $in }  # `default {}` might interpret it as a closure and thus keep in null and `default {|| {}}` does not work with old versions
				| transpose k v
				| each {|i| (
					($env | transpose k v | where $it.k == $i.k).0?.v?
				) in $i.v}
				| all {|i| $i }
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
	let package_configs = (^$nu.current-exe --commands (
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
		$"    NU_LIB_DIRS: \($env.NU_LIB_DIRS? | default [] | append [($lib_dirs)]\)"
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
					let meta = (open --raw $meta_file | decode 'utf-8' | from nuon)
					[(
						$meta.modules?
						| default []
						| where not ($it in $package.disabled_modules)
						| each {|module|
							$'export use ($package.dir)/($module).nu *'
						}
					), (
						$meta.prefixed_modules?
						| default []
						| where not ($it in $package.disabled_modules)
						| each {|module|
							$'export use ($package.dir)/($module).nu'
						}
					)] | flatten
				}
			} | compact | flatten
		)
	] | flatten
	| str join (char nl)
	| save --force $init_file
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
					print --stderr $"(ansi r)Failed to link (ansi rb)($package.source)(ansi r) due to the folder being absent(ansi reset)"
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
	let header_color = ($env.config?.color_config?.header? | default green_bold)
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
		if not $quiet and ($update_info | length) > 1 {
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
		| where name == 'packer.nu' | $in.0? | default {}
	))
	print $'Nu version: (nu --version | str trim)'
	print $'OS: ($nu.os-info.name)'
	print $'Packer version: ($packer_meta.version? | default "?")'
	print ''

	if $package_name != '' {
		let package = (
			config get packages
			| where source =~ $package_name
			| $in.0?
		)
		if $package == null {
			print --stderr $'Unable to find package "($package_name)"'
		} else {
			print $package_name
			print $'($package)'
			let meta = (meta load $package)
			if $meta != null {
				print $'version: ($meta.version? | default "?")'
				print $'git-commit: ($meta.current_git_commit?)'
			}
		}
	}
}

# get the status of packer.nu
export def status [] {
	if 'packer_api' in (
		overlay list
		| if ($in | describe) =~ '^table' { where $it.active == true | get name } else { $in }  # https://www.nushell.sh/blog/2025-09-02-nushell_0_107_0.html#add-active-column-to-overlay-list-16125-toc
	) {
		print $'(ansi c)API-Layer: (ansi g)loaded'
	} else {
		print $'(ansi c)API-Layer: (ansi rb)not loaded'
		print $'  (ansi c)reload: (ansi ligr)overlay use ($env.NU_PACKER_HOME)/start/packer.nu/api_layer/packer_api.nu'
	}
	if 'packer_packages' in (
		overlay list
		| if ($in | describe) =~ '^table' { where $it.active == true | get name } else { $in }  # https://www.nushell.sh/blog/2025-09-02-nushell_0_107_0.html#add-active-column-to-overlay-list-16125-toc
	) {
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

	for name in (ls --short-names $'($env.NU_PACKER_HOME)/start').name {
		if not $name in $used {
			print $'"($name)" is unused.'
			rm --recursive --permanent --interactive-once $'($env.NU_PACKER_HOME)/start/($name)'
		}
	}
	return
}
