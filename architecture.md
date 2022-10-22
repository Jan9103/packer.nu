# Packer.nu Architecture

## Loading everything
`$nu.env-path`:
1. loads `api_layer/packer_api.nu` as overlay
	1. the `packer` command (loading it here helps with recovery in case something breaks)
	2. some library functions, such as `parsed rg`

`$nu.config-path`:
1. loads `~/.local/share/nushell/packer/packer_packeages.nu` as overlay
	- the always-active plugins
2. generates `~/.local/share/nushell/packer/conditional_packages.nu`
	- the conditional packages
3. loads `…/conditional_packages.nu` as overlay

