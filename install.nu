let tilde_expansion_should_work = ($'/home/($env.USER)' == $env.HOME)

let PACKER_REPO = 'https://github.com/jan9103/packer.nu'
let NU_CONFIG_DIR = ($nu.config-path | path dirname)
let PACKER_DIR = (
	if $tilde_expansion_should_work { '~/.local/share/nushell/packer'
	} else { $'($env.HOME)/.local/share/nushell/packer' }
)
let PACKER_PACKAGE_DIR = $'($PACKER_DIR)/start/packer.nu'


# append some lines to a file
def 'append_to_file' [
	file: path
	lines: list
] {
	open $file
	| lines
	| append $lines
	| str join (char nl)
	| save -f $file
}


def main [] {
	for subdir in ['start', 'bin', 'lib'] {
		mkdir $'($PACKER_DIR)/($subdir)'
	}

	if not ($'($NU_CONFIG_DIR)/packages.nuon' | path exists) {
		$"{\n\tpackages: [\n\t\t{source: '($PACKER_REPO)'}\n\t]\n}\n# vim: ft=nu"
		[
			'{'
			'	packages: ['
			$"		{source: '($PACKER_REPO)'}"
			'	]'
			'}'
			'# vim: ft=nu'
		]
		| str join (char nl)
		| save -r $'($NU_CONFIG_DIR)/packages.nuon'
	}

	# install packer as package
	if not ($PACKER_PACKAGE_DIR | path exists) {
		git clone $PACKER_REPO $PACKER_PACKAGE_DIR
	}

	# create a fallback loader, which loads packer
	if not ($'($PACKER_DIR)/packer_packages.nu' | path exists) {
		touch $'($PACKER_DIR)/packer_packages.nu'
	}
	if not ($'($PACKER_DIR)/conditional_packages.nu' | path exists) {
		touch $'($PACKER_DIR)/conditional_packages.nu'
	}

	if not (open $nu.env-path | str contains "\n### packer.nu ###\n") {
		append_to_file $nu.env-path ([
			''
			'### packer.nu ###'
			# Bootstrapping currently does not work since nu-script checks
			# the existence of every used overlay pre execution
			# (if $tilde_expansion_should_work { [
			# 	'# bootstrap packer.nu'
			# 	$"if not \('($PACKER_PACKAGE_DIR)/api_layer/packer_api.nu' | path exists\) {"
			# 	'  nu -c (fetch https://raw.githubusercontent.com/jan9103/packer.nu/main/install.nu)'
			# 	'}'
			# ] })
			'# load packer api-layer'
			$'overlay use ($"($PACKER_PACKAGE_DIR)/api_layer/packer_api.nu")'
			'# generate list for conditional packages'
			$'packer compile_cond_init ($"($PACKER_DIR)/conditional_packages.nu")'
		] | flatten | compact)
	}

	if not (open $nu.config-path | str contains "\n### packer.nu ###\n") {
		append_to_file $nu.config-path [
			''
			'### packer.nu ###'
			'# load packages'
			$'overlay use ($"($PACKER_DIR)/packer_packages.nu")'
			'# load conditional packages'
			$'overlay use ($"($PACKER_DIR)/conditional_packages.nu")'
		]
	}
}
