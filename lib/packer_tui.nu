# let the user select a item of a list
# returns:
#  the selected item
#  default: null
export def select [
	options: list
] {
	$options | each {|i| print $'($i.index): ($i.item)'}
	let s = (input '> ')
	if $s =~ '^\d+$' {
		$options | get -i ($s | into int)
	} else { null }
}
