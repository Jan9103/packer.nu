def 'config load' [] {open $'($nu.env-path | path dirname)/packages.nuon'}

# API-INTERFACE: Parse a package dnfinition from packages.nuon
export def 'config parse package' [
	package: record  # the package entry
] {
	let name = (
		$package | get -i as
		| default ($package.source | path basename)
	)
	{
		source: $package.source
		deactivate: ($package | get -i deactivate | default false)
		freeze: ($package | get -i freeze | default false)
		opt: ($package | get -i opt | default false)
		name: $name
		dir: (
			if ($package | get -i opt | default false) {
				$'($env.NU_PACKER_HOME)/opt/($name)'
			} else {$'($env.NU_PACKER_HOME)/start/($name)'}
		)
		config: ($package | get -i config)
		condition: ($package | get -i condition)
	}
}

# API-INTERFACE: Get packages defined in packages.nuon
export def 'config get packages' [] {
	config load
	| get -i packages | default []
	| par-each {|package| config parse package $package}
}

def 'meta load' [
	package  # "config get packages" object
] {
	let file = $'($package.dir)/meta.nuon'
	if ($file | path exists) {
		let git_commit = (
			if ($'($package.dir)/.git' | path exists) {
				git log --oneline --no-abbrev-commit
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

def version_comparison [
	version_a #: list<int> # [mayor minor patch]
	version_b #: list<int> # [mayor minor patch]
] {
	if $version_a.0 > $version_b.0 {'>'
	} else if $version_a.0 < $version_b.0 {'<'
	} else {
		if $version_a.1 > $version_b.1 {'>'
		} else if $version_a.1 < $version_b.1 {'<'
		} else { '=='}  # <- dont ask me why nu requires a space there..
	}
}

def nu_escape_string [text: string] {
	$text | str replace '[^a-zA-Z0-9]' '_'
}

# (re-)generate the init-system
# is automatically executed after install and update
export def compile [] {
	print 'Compiling init-system'
	let nu_version = nu_version
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition == null
		| par-each {|package|
			$package
			| insert meta {meta load $package}
		}
		| find -p {|package|
			let min_nu_version = ($package.meta | get -i min_nu_version | default [0 0 0])
			let max_nu_version = ($package.meta | get -i max_nu_version | default [9999 0 0])

			[
				($package.dir | path exists)  # filter not installed ones
				# filter by min and max version
				((version_comparison $nu_version $min_nu_version) != '<')
				((version_comparison $nu_version $max_nu_version) != '>')
			] | all $it
		}
	)
	generate_init_file $packages $'($env.NU_PACKER_HOME)/packer_packages.nu'
}

# not meant to be manually executed.
# used to generate the init-system conditional packages
export def compile_cond_init [file: path] {
	let nu_version = nu_version
	let packages = (
		config get packages
		| where not opt
		| where not deactivate
		| where condition != null
		| par-each {|package| $package | insert meta {meta load $package}}
		| find -p {|package|
			let min_nu_version = ($package.meta | get -i min_nu_version | default [0 0 0])
			let max_nu_version = ($package.meta | get -i max_nu_version | default [9999 0 0])
			[
				($package.dir | path exists)
				((version_comparison $nu_version $min_nu_version) != '<')
				((version_comparison $nu_version $max_nu_version) != '>')
				(
					$package.condition
					| get -i env | default {}
					| transpose k v
					| each {|i| ($env | get -i $i.k) in $i.v}
					| all $it
				)
			] | all $it
		}
	)
	#print $'conditional packages: ($packages | get -i name | str join " ")'
	#if ($packages | length) == 0 { '' | save -r $file
	#} else {generate_init_file $packages $file}
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
		$"  let-env NU_LIB_DIRS = \($env | get -i NU_LIB_DIRS | default [] | append [($lib_dirs)]\)"
		$'  let-env NU_PACKER_CFG = ($package_configs)'
		(
			$packages
			| par-each {|i|
				let file = $'($i.dir)/env.nu'
				if ($file | path exists) {
					$'  source-env ($file)'
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
			| par-each {|i|
				let meta_file = $'($i.dir)/meta.nuon'
				if ($meta_file | path exists) {
					open $meta_file
					| get -i modules | default []
					| each {|module|
						$'export use ($i.dir)/($module).nu'
					}
				}
			} | compact | flatten
		)
	] | flatten
	| str join (char nl)
	| save $init_file
}

# install the packages newly added to the packages.nuon
export def install [
	--yes(-y)  # run post_install scripts without asking
] {
	config get packages
	| par-each {|package|
		if not ($package.dir | path exists) {
			print $'Installing ($package.name)'
			if ($package.source | str substring [0,1]) in ['~', '/'] {
				print '-> Linking dir'
				ln -s ($package.source | path expand) $package.dir
			} else {
				print '-> Downloading'
				let URL = (
					if ($package.source | str contains '://') {
						$package.source
					} else {$'https://github.com/($package.source)'}
				)
				git clone $URL $package.dir
			}
			if ($'($package.dir)/post_install.nu' | path exists) {
				if $yes {
					print '-> Running post install'
					nu $'($package.dir)/post_install.nu'
				} else {
					if (input 'Run postinst? (y/n): ') in ['yes' 'y'] {
						print '-> Running post install'
						nu $'($package.dir)/post_install.nu'
					}
				}
			}
		} # end: if not dir exists
	} # end: looping over packages
	compile  # TODO: deactivate via config
}

# update installed packages
export def update [] {
	# local repos are symlinks -> not updated
	# manually added dirs dont have '.git/' -> not updated
	print 'Updating packages:'
	config get packages
	| where freeze == false
	| par-each {|package|
		if ($'($package.dir)/.git' | path exists) and (($package.dir | path type) == 'dir') {
			print $' - ($package.name)'
			cd $package.dir
			^git pull -q --ff-only
		}
	}
	compile  # TODO: deactivate via config
}

export def debuginfo [
	package_name: string = ''
] {
	let packages = config get packages
	let packer_meta = meta load (
		$packages
		| where name == 'packer.nu' | get -i 0 | default {}
	)
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
			let meta = meta load $package
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
