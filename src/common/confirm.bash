#!/bin/bash

#
# Usage:
#
# confirm 'Are you sure?'
#   && echo 'true'
#   || echo 'false'
#

confirm() {
	test -z "$1" && 1='Confirm?'
	_resp=
	while [ "$_resp" != 'y' ] && [ "$_resp" != 'n' ]; do
		read -ep "$1 (y/n): " _resp
		_resp=$(echo $_resp | head -c 1)
	done
	test "$_resp" = 'y' && return 0 || return 1
}
