
#
# Copyright © 2013 Max Ruman
#
# This file is part of Wok.
#
# Wok is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# Wok is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Wok. If not, see <http://www.gnu.org/licenses/>.
#

#
# Check if an index contains a token
#
# Usage: index_has <index_path> <token>
#
index_has()
{
	local index_path="$1"
	local token="$2"
	local index_token

	if [[ ! -f $index_path || ! -r $index_path ]]; then
		return 1
	fi

	while read index_token; do
		if [[ $index_token == $token ]]; then
			return 0
		fi
	done <"$index_path"

	return 1
}

#
# Add a token to an index
#
# Usage: index_add <index_path> <token>
#
index_add()
{
	local index_path="$1"
	local token="$2"
	local index_dir="$(dirname "$index_path")"

	if [[ ! -f $index_path ]]; then
		if [[ ! -d $index_dir ]]; then
			mkdir -p "$index_dir"
		fi
		touch "$index_path"
	fi

	if [[ ! -f $index_path || ! -w $index_path ]]; then
		echo "Can't use '${index_path}' as index file." >&2
		return 1
	fi

	if index_has "$index_path" "$token"; then
		return 2
	fi

	echo "$token" >>"$index_path"
}

#
# Remove a token from an index
#
# Usage: index_remove <index_path> <token>
#
index_remove()
{
	local index_path="$1"
	local token="$2"
	local index_token
	local tmp_file
	local found=false
	local index_dir="$(dirname "$index_path")"

	if [[ ! -f $index_path ]]; then
		if [[ ! -d $index_dir ]]; then
			mkdir -p "$index_dir"
		fi
		touch "$index_path"
	fi

	if [[ ! -f $index_path || ! -w $index_path ]]; then
		echo "Can't use '${index_path}' as index file." >&2
		return 1
	fi

	if ! tmp_file="$(mktemp)"; then
		echo "Could not create a temporary file." >&2
		exit -1
	fi

	while read index_token; do
		if [[ $index_token == $token ]]; then
			found=true
			continue
		fi
		echo "$index_token" >>"$tmp_file"
	done <"$index_path"

	if $found; then
		mv "$tmp_file" "$index_path"
		return 0
	fi

	rm "$tmp_file"
	return 1
}
