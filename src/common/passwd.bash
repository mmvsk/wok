#!/bin/bash

passwd() {
	local length="$(echo "$1" | tr -dc '0-9')"
	local rand_src=/dev/random
	local human_readable=true

	if $human_readable; then
		# human readabl3 passwords: non-confusing letters
		local replace_chars=('1' '%' 'l' '-' 'I' '\$' '0' '&' 'O' '@')

	else
		# non interactive passwords: just keep it as is
		local replace_chars=('\+' '-' '\/' '_')
	fi

	if [[ -z $length || $length -lt 1 ]]; then
		length=16
	fi

	part=0
	regex=""
	for c in "${replace_chars[@]}"; do
		if [[ $part -eq 0 ]]; then
			regex="${regex}s/${c}"
			part=1
		else
			regex="${regex}/${c}/g;"
			part=0
		fi
	done

	pass="$(dd if=/dev/random bs=1 count=$length 2>/dev/null | base64 | head -c $length | perl -pe "$regex")"

	echo "$pass"
}
