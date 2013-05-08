#!/bin/bash

#
# Usage:
#
# getpasswd var
#

getpasswd() {
	test -z "$1" && echo "Requires variable name" && exit 1
	local var=$1
	local _getpasswd_password_match=
	local _getpasswd_confirm=
	local _getpasswd_password=
	while [ ! $_getpasswd_password_match ]; do
		read -s -ep 'Password: ' _getpasswd_password; echo
		read -s -ep 'Password (confirmation): ' _getpasswd_password_confirm; echo
		if [ ${#_getpasswd_password} -le 0 ]; then
			echo "Password can't be null, please try again..."
		elif [ "$_getpasswd_password" != "$_getpasswd_password_confirm" ]; then
			echo "Password mismatch, please try again..."
		else
			_getpasswd_password_match=1
			printf -v "$var" %s "$_getpasswd_password"
		fi
	done
}
