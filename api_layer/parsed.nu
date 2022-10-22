# Parsed program outputs

# ripgrep
# returns:
#   list:
#     'file': string
#     'line': int
#     'column': int
#     'content': string
export def rg [
	--ignore-case(-i)
	--case-sensitive(-s)
	--hidden  # include hidden files and directories
	--invert-match(-v)
	regex: string
	paths: path:list = []
] {
	let options = ([
		(if $ignore_case {'-i'})
		(if $case_sensitive {'-s'})
		(if $hidden {'--hidden'})
		(if $invert_match {'-v'})
	] | compact)
	^rg --vimgrep --no-config $options -- $regex $paths
	| lines
	| parse '{file}:{line}:{column}:{content}'
	| each {|i|
		$i
		| update line {$i.line | into int}
		| update column {$i.column | into int}
	}
}
