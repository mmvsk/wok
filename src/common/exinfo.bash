exinfo_interactive() {
	[[ -t 0 ]]
}

exinfo_file() {
	readlink -f "$0"
}

exinfo_dir() {
	dirname "$(exinfo_file)"
}
