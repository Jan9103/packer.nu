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
				if $editor in ['vi', 'vim', 'nvim', 'emacs', 'ne'] { $editor
				} else { 'nano' }
			)
			nu -c ([
				$editor
				(if $line != null {$"+($line)"})
				($file | into string | to json)  # escape spaces, etc
			] | compact | str join ' ')
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
