# This file is loaded by $nu.env-path as 'packer_api' overlay and loads:
# - the important parts of packer (for recovery, etc)
# - packer-api-layer features such as `parsed rg` for plugins

export-env {
	let-env NU_PACKER_HOME = $'($env.HOME)/.local/share/nushell/packer'
	let-env NU_PACKER_UNIFIED = {
		downloader: {|url,dir,file,headers,timeout|
			let headers = (
				$headers  # {a: b}
				| transpose k v  # [{k: a, v: b}]
				| each {|i| [$i.k $i.v]}  # [[a b]]
				| flatten  # [a b]
			)
			fetch -r -H $headers -t $timeout $url
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
