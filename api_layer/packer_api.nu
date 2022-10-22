# This file is loaded by $nu.env-path as 'packer_api' overlay and loads:
# - the important parts of packer (for recovery, etc)
# - packer-api-layer features such as `parsed rg` for plugins

export-env {
	let-env NU_PACKER_HOME = $'($env.HOME)/.local/share/nushell/packer'
	let-env config = (
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
