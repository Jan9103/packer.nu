# append a pre_prompt hook to the hook-config
export def --env 'hook append pre_prompt' [
	block  # (:closure/block) the code-block - example: {print 'foo'}
] {
	load-env {config: ($env.config | upsert hooks.pre_prompt {|config|
		$config.hooks?.pre_prompt? | default [] | append $block
	})}
}

# append a pre-execution hook to the config
export def --env 'hook append pre_execution' [
	block  # (:closure/block) the code-block - example: {print 'foo'}
] {
	load-env {config: ($env.config | upsert hooks.pre_execution {|config|
		$config.hooks?.pre_execution? | default [] | append $block
	})}
}

# append a env-change hook to the config
# content can be 1 of 2 schemes:
# 1. a block:
#    {|before, after| print 'foo'}
# 2. a dict with condition and block:
#    {
#      condition: {|before, after| $after == /some/path/to/directory }
#      code: {|before, after| load-env { SPAM: eggs } }
#    }
export def --env 'hook append env_change' [
	variable_name: string
	content
] {
	load-env {config: ($env.config | upsert hooks.env_change {|config|
		$config.hooks?.env_change?
		| default {}
		| upsert $variable_name {|envc|
			$envc | get --ignore-errors $variable_name | default [] | append $content
		}
	})}
}
