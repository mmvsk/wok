
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

#-----------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------

wok_path=/usr/local/share/wok
wok_config=/usr/local/etc/wok/wok.ini
wok_repo=/var/local/lib/wok

#-----------------------------------------------------------------------
# ...
#-----------------------------------------------------------------------

# Stub
#======

export PATH=$PATH:$wok_path/bin

. "$wok_config"
for f in $wok_path/inc/*; do
	. "$f"
done

# Parameters
#============

usage() {
	test -n "$1" && echo -e "$1\n"
	echo "Usage: wok <module>"
	echo
	echo "$(
		cd $wok_path
		ls -1 wok-* | sed 's/^wok-/    /' | sed 's/$/ [options]/'
	)"
	echo
	exit 1
}

# Processing
module="$1";shift

# Validation
test -z "$module" && usage
test ! -f "$wok_path/wok-$module" && usage "Invalid module."

# Run
#=====
. "$wok_path/wok-$module" $*
