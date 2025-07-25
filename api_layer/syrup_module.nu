# module(s) for the <https://github.com/Jan9103/syrup> shell prompt
# "source-env" this and use it. the defaults should be enough docs.

# module name: "packer_degration"
const DEGRATION_DEFAULT: record = {
  'format': {
    'ok': ''
    'packages_gone': $' (ansi red)PACKER-PACKAGES FAILED TO LOAD(ansi reset)'
    'api_gone': $' (ansi red)PACKER-API FAILED TO LOAD(ansi reset)'
  }
}

export-env {
  $env.SYRUP_PROMPT_MODULES.'packer_degration' = {|cfg|
    let cfg: record = ($DEGRATION_DEFAULT | merge deep $cfg)
    let overlays = (overlay list)
    if 'packer_api' not-in $overlays {
      $cfg.format.api_gone
    } else if 'packer_packages' not-in $overlays {
      $cfg.format.packages_gone
    } else {
      $cfg.format.ok
    }
  }
}
