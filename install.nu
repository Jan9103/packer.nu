# less, tmux, etc do not continue colors on the next line -> set them at the beginning of every line
let RESET_LINE = $'(ansi esc)[0G(ansi esc)[K'
# ESC[0G = jump to beginning of line; ESC[K = erase line
print $'(ansi g)Installing packer.nu.'
print $'(ansi g)====================='
print -n $'(ansi y)Setting up install env..'
let tilde_expansion_should_work = ($'/home/($env.USER)' == $env.HOME)

let PACKER_REPO = 'https://github.com/jan9103/packer.nu'
let NU_CONFIG_DIR = ($nu.history-path | path dirname)
let PACKER_DIR = (
	if $tilde_expansion_should_work { '~/.local/share/nushell/packer'
	} else { $'($env.HOME)/.local/share/nushell/packer' }
)
let PACKER_PACKAGE_DIR = $'($PACKER_DIR)/start/packer.nu'
let ABS_PACKER_DIR = ($PACKER_DIR | path expand)
let ABS_PACKER_PACKAGE_DIR = ($PACKER_PACKAGE_DIR | path expand)
print $'($RESET_LINE)(ansi g)Install env is set up'

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


print -n $'(ansi y)Creating directories..'
for subdir in ['start', 'bin', 'lib'] {
	mkdir $'($ABS_PACKER_DIR)/($subdir)'
}
print $'($RESET_LINE)(ansi g)Created directories.'

if not ($'($NU_CONFIG_DIR)/packages.nuon' | path exists) {
	print -n $'(ansi y)Creating defaut packages.nuon..'
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
	print $'($RESET_LINE)(ansi g)Created default packages.nuon.'
} else { print $'(ansi b)kept existing packages.nuon.' }

# install packer as package
if not ($PACKER_PACKAGE_DIR | path exists) {
	print $'(ansi y)Git cloning packer.nu:(ansi reset)'
	mkdir $'($ABS_PACKER_DIR)/start'
	^git clone $PACKER_REPO $ABS_PACKER_PACKAGE_DIR
	print $'(ansi g)Git cloned packer.nu.'
} else { print $'(ansi u)Already git cloned packer.nu.' }

let regenerate_config = not (open $nu.config-path | str contains "\n### packer.nu ###\n")
let regenerate_env = not (open $nu.env-path | str contains "\n### packer.nu ###\n")
let enable_conditional_loading = (
	if $regenerate_env {
		print ''
		print $'(ansi yb)Do you want to use conditional packages?(ansi reset)'
		print $'(ansi y)  very few packages require it and it slows'
		print $'(ansi y)  down your startup-time quite a bit.'
		print $"(ansi y)  you can enable/disable it later by \(un-)commenting"
		print $'(ansi y)  a line in your env.nu and config.nu each.'
		input '(y/n)> '
	} else {'y'}
)

if $regenerate_env {
	print -n $'(ansi y)Adding packer load section to ($nu.env-path).'
	append_to_file $nu.env-path ([
		''
		'### packer.nu ###'
		(if ($PACKER_DIR | str starts-with '~') {
			# if '~' is used we have to expand it
			# ther reason why tilde is preferred is for portability
			$"let-env NU_PACKER_HOME = \('($PACKER_DIR)' | path expand\)"
		} else {
			$"let-env NU_PACKER_HOME = '($PACKER_DIR)'"
		})

		'# recovery command'
		"def 'packer compile' [] { nu -c $'use ($env.NU_PACKER_HOME)/start/packer.nu/api_layer/packer.nu; packer compile' }"

		'# bootstrap packer.nu'
		"if not ($'($env.NU_PACKER_HOME)/start/packer.nu/api_layer/packer_api.nu' | path exists) {"
		"  print $'(ansi ub)Bootstrapping packer.nu...(ansi reset)'"
		'  nu -c (http get https://raw.githubusercontent.com/jan9103/packer.nu/main/install.nu)'
		"  print $'(ansi ub)Bootstrapped packer.nu.'"
		"  print $'(ansi ub)Installing packages...(ansi reset)'"
		"  nu -c $'use ($env.NU_PACKER_HOME)/start/packer.nu/api_layer/packer.nu; packer install'"
		"  print $'(ansi ub)Installed packages.(ansi reset)'"
		'}'
		'# compile conditional package loader'
		"# conditional packages have to be generated in the env, since you can't generate and import in the same file."
		(if $enable_conditional_loading == 'y' {
			$"nu -c 'use ($PACKER_DIR)/start/packer.nu/api_layer/packer.nu; packer compile_cond_init ($PACKER_DIR)/conditional_packages.nu'"
		} else {
			$"#nu -c 'use ($PACKER_DIR)/start/packer.nu/api_layer/packer.nu; packer compile_cond_init ($PACKER_DIR)/conditional_packages.nu'"
		})

		"if not ($'($env.NU_PACKER_HOME)/packer_packages.nu' | path exists) { 'export-env {}' | save $'($env.NU_PACKER_HOME)/packer_packages.nu' }"
	] | flatten | compact)
	print $'($RESET_LINE)(ansi g)Added packer load section to ($nu.env-path).'
} else { print $'(ansi u)Skipped adding packer load section to ($nu.env-path) to avoid duplicates.' }

if $regenerate_config {
	print -n $'(ansi y)Adding packer load section to ($nu.config-path)..'
	append_to_file $nu.config-path [
		''
		'### packer.nu ###'
		'# load packer api'
		$"overlay use ($PACKER_PACKAGE_DIR)/api_layer/packer_api.nu"
		'# load packages'
		$'overlay use ($PACKER_DIR)/packer_packages.nu'
		'# load conditional packages'
		(if $enable_conditional_loading == 'y' {
			$'overlay use ($PACKER_DIR)/conditional_packages.nu'
		} else {
			$'#overlay use ($PACKER_DIR)/conditional_packages.nu'
		})
	]
	print $'($RESET_LINE)(ansi g)Added packer load section to ($nu.config-path).'
} else { print $'(ansi u)Skipped adding packer load section to ($nu.config-path) to avoid duplicates.' }

if not ($'($ABS_PACKER_DIR)/conditional_packages.nu' | path exists) {
	'export-env {}' | save -r $'($ABS_PACKER_DIR)/conditional_packages.nu'
}

print $'(ansi g)Finished install script.(ansi reset)'
