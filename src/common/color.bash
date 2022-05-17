#!/bin/bash

#
# Change the color of a text.
#
# Usage #1: echo "Hello world!" | color green
# Usage #2: echo "$(color brown 'John')> Hi!"

color() {
	local color="$1"
	local message="$2"

	if [[ -z $message ]]; then
		message="$(less <&0)"
	fi

	# skip coloring if it's not interactive
	if ! [[ -t 0 ]]; then
		echo "$message"
		return 0
	fi

	for color in $(echo "$color" | perl -pe "s/[^a-z0-9_-]+/ /g"); do
		case "$color" in
			off)       code=0 ;;
			none)      code=0 ;;
			bold)      code=1 ;;
			dim)       code=2 ;;
			underline) code=4 ;;
			blink)     code=5 ;;
			invert)    code=7 ;;
			reverse)   code=7 ;;
			hide)      code=8 ;;

			white)   code=97 ;;
			black)   code=30 ;;
			red)     code=31 ;;
			green)   code=32 ;;
			yellow)  code=33 ;;
			blue)    code=34 ;;
			magenta) code=35 ;;
			cyan)    code=36 ;;
			grey)    code=37 ;;
			gray)    code=37 ;;

			xgrey)    code=90 ;;
			xgray)    code=90 ;;
			xred)     code=91 ;;
			xgreen)   code=92 ;;
			xyellow)  code=93 ;;
			xblue)    code=94 ;;
			xmagenta) code=95 ;;
			xcyan)    code=96 ;;

			*)
				return 1 ;;
		esac

		message="\e[${code}m${message}\e[0m"
	done

	echo -e "$message"
}
