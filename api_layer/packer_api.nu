export-env {
	let IS_WINDOWS = ($nu.os-info.family == 'windows')
	load-env {NU_PACKER_HOME: ($env | get -i NU_PACKER_HOME | default (if ($IS_WINDOWS) { 
		$'($env.LOCALAPPDATA)/nushell/packer' 
	} else {
		$"($env.HOME)/.local/share/nushell/packer" 
	}))}

  source-env packer_stdlib.nu
}

export use packer_stdlib.nu *
export use packer.nu
