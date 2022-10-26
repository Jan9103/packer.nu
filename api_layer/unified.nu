# Download a URl into a File
# examples:
#    unified download https://www.gnu.org/fun/jokes/ed-msg.html
#    unified download https://www.gnu.org/fun/jokes/ed-msg.html ~/Downloads/
#    unified download https://www.gnu.org/fun/jokes/ed-msg.html ~/Downloads/ED.html
export def download [
	url: string  # The URL you want to download
	save_location: path = '.'  # where to save it (file or directory)
	--headers: record  # http request headers
	--timeout: int = 30  # timeout in seconds
] {
	let save_location = ($save_location | path expand)
	let target_location = (
		if ($save_location | path type) == 'dir' {
			{
				dir: $save_location,
				file: ($url | path basename),
			}
		} else {
			{
				dir:  ($save_location | path dirname),
				file: ($save_location | path basename),
			}
		}
	)
	(do $env.NU_PACKER_UNIFIED.downloader
		$url
		$target_location.dir
		$target_location.file
		($headers | default {})
		$timeout
	)
}

# Open a file in a CLI text editor
export def editor [
	file: path  # the file you want to edit
	line?: int
] {
	do $env.NU_PACKER_UNIFIED.editor $file $line
}
