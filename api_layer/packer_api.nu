# This file is loaded by $nu.env-path as 'packer_api' overlay and loads:
# - the important parts of packer (for recovery, etc)
# - packer-api-layer features such as `parsed rg` for plugins

export-env {
	if ($env | get -i NU_PACKER_HOME) == null {
		print $"(ansi ub)You have updated to packer.nu 0.4.\n(ansi ub)This version changed the attach method in order to allow bootstrapping, etc.\n(ansi rb)Please remove the packer section from (ansi lg)$.nu.config-path(ansi rb) and (ansi lg)$nu.env-path(ansi rb) and rerun the installer (ansi lg)nu -c \(http get https://raw.githubusercontent.com/jan9103/packer.nu/master/install.nu\)(ansi rb).(ansi reset)"
	}
	
	let IS_WINDOWS = ($nu.os-info.family == 'windows')

	load-env {NU_PACKER_HOME: ($env | get -i NU_PACKER_HOME | default (if ($IS_WINDOWS) { 
		$'($env.LOCALAPPDATA)/nushell/packer' 
	} else {
		$"($env.HOME)/.local/share/nushell/packer" 
	}))}

	load-env {NU_PACKER_UNIFIED: {
		downloader: {|url,dir,file,headers,timeout|
			let headers = (
				$headers  # {a: b}
				| transpose k v  # [{k: a, v: b}]
				| each {|i| [$i.k $i.v]}  # [[a b]]
				| flatten  # [a b]
			)
			let v = ((nu --version | split row '.').1 | into int)
			http get -r -H $headers -m $timeout $url
			| save -r $'($dir)/($file)'
		}
		editor: {|file,line|
			let editor = ($env | get -i EDITOR)
			let editor = (
				if $editor in ['vi', 'vim', 'nvim', 'emacs', 'ne', 'micro', 'nano', 'code', 'kibi', 'amp', 'hx', 'helix'] { 
					$editor
				} else { 
					if ($IS_WINDOWS) {
						'notepad' # Nano isn't installed by default on windows
						# NOTE: It is possible to have a windows install without notepad
					} else {
						'nano' # Nano also appears in the list above as it can be installed on windows
					}
				}
			)

			let file = ($file | into string)

			nu -c ((if ($editor == 'code') { # VSCode or VSCodium
				print $"(ansi c)Waiting for Code to close the file...(ansi reset)" # Message to user
				[
					code
					(if ($line != null) {
						$"--goto '($file):($line)'" # Don't cast to json. The quotes need to wrap the line number
					} else { 
						($file | to json)
					})
					--wait 
				]
			# FILE:LINE
			} else  if ($editor in ['hx', 'helix']) {
				[
					$editor
					(if ($line == null) {$file} else {$'($file):($line)'} | to json)
				]
			# NO LINE SUPPORT
			} else if ($editor in ['kibi', 'notepad']) {
				[
					$editor
					($file | to json)
				]
			# FILE +LINE
			} else {
				[
					$editor
					(if ($line != null) {$"+($line)"})
					($file | to json)
				]
			}) | compact | str join ' ')
		}
	}}

	load-env {config: (
		# Broken ?
		# `let-env TEST = 'FOO'` dosnt work afterwards
		# this runs fine in interactive
		$env.config
		| upsert hooks {|config|
			# TODO: keep existing hooks
			{
				pre_prompt: []
				pre_execution: []
				env_change: {}
			}
		}
	)}
}


export use nuconfig.nu
export use packer.nu
export use parsed.nu
export use unified.nu
