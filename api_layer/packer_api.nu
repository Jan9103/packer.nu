# This file is loaded by $nu.env-path as 'packer_api' overlay and loads:
# - the important parts of packer (for recovery, etc)
# - packer-api-layer features such as `parsed rg` for plugins

export-env {
	if ($env | get -i NU_PACKER_HOME) == null {
		print $"(ansi ub)You have updated to packer.nu 0.4.\n(ansi ub)This version changed the attach method in order to allow bootstrapping, etc.\n(ansi rb)Please remove the packer section from (ansi lg)$.nu.config-path(ansi rb) and (ansi lg)$nu.env-path(ansi rb) and rerun the installer (ansi lg)nu -c \(http get https://raw.githubusercontent.com/jan9103/packer.nu/master/install.nu\)(ansi rb).(ansi reset)"
	}
	let-env NU_PACKER_HOME = ($env | get -i NU_PACKER_HOME | default $"($env.HOME)/.local/share/nushell/packer")

	let-env NU_PACKER_UNIFIED = {
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
				if $editor in ['vi', 'vim', 'nvim', 'emacs', 'ne', 'micro', 'nano', 'code'] { 
					$editor
				} else { 
					if ($nu.os-info == 'windows') {
						'notepad' # Nano isn't installed by default on windows
					} else {
						'nano' # Nano also appears in the list above because it could be installed on windows
					}
				}
			)

			let file = ($file | into string | to json)

			# Different editors have different syntax
			let editor_cmd = if ($editor == 'notepad') {
				[
					notepad # notepad has a very limited CLI and doesnt support line numbers
					$file
				]
			} else if ($editor == 'code') {
				[
					code
					(if $line != null {$"--goto ($file):($line)"} else { $file }) 
					--wait # wait for vscode to close
				]
			} else {
				[
					$editor
					(if $line != null {$"+($line)"})
					$file
				]
			}

			# Invoke editor
			nu -c ($editor_cmd | compact | str join ' ')
		}
	}

	let-env config = (
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
	)
}


export use nuconfig.nu
export use packer.nu
export use parsed.nu
export use unified.nu
