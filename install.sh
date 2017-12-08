#!/bin/bash

base="`dirname "$0"`"
action=install
req_root=true
install_path=/usr/local/share
conf_path=/usr/local/etc
data_path=/var/local/lib
bin_path=/usr/local/bin

usage()
{
	echo "Usage: ${0} [install|reinstall|remove|purge] [--user] <paths...>"
	echo
	echo "    --install-path=<path>  e.g. /usr/local/share"
	echo "    --conf-path=<path>     e.g. /usr/local/etc"
	echo "    --data-path=<path>     e.g. /var/local/lib"
	echo "    --bin-path=<path>      e.g. /usr/local/bin"
	echo
}

install()
{
	local wok_bin="${bin_path}/wok"
	local wok_bin_elf="${install_path}/wok/wok.elf"
	local wok_bin_bash="${install_path}/wok/wok.bash"

	if $req_root && test `id -u` -ne 0; then
		echo "Wok must be installed as root." >&2
		return 1
	fi
	if test -e "$install_path/wok" || test -e "$bin_path/wok"; then
		echo "Is Wok already installed?" >&2
		return 1
	fi
	echo -n "Installing Wok..."
	cp -r "$base/dist/wok" "$install_path"
	test ! -d "$conf_path/wok" && cp -r "$base/dist/conf" "$conf_path/wok"
	test ! -d "$data_path/wok" && cp -r "$base/dist/repo" "$data_path/wok"
	chmod -R o=,g= "$conf_path/wok"
	chmod -R o= "$data_path/wok"
	test -f "$wok_bin_elf" && ln -sf "$wok_bin_elf" "$wok_bin" || ln -sf "$wok_bin_bash" "$wok_bin"
	echo "done."
}

uninstall()
{
	if test ! -d "$install_path/wok" && test ! -f "$bin_path/wok"; then
		echo "Wok is not installed on this system" >&2
		return 1
	fi
	echo -n "Uninstalling..."
	rm -rf "$install_path/wok"
	rm -f "$bin_path/wok"
	echo "done."
}

reinstall()
{
	uninstall
	install
}

purge()
{
	uninstall
	if test ! -d "$conf_path/wok" &&  test ! -d "$data_path/wok"; then
		echo "Wok is not configured on this system" >&2
		return 1
	fi
	echo -n "Purging..."
	rm -rf "$conf_path/wok"
	rm -rf "$data_path/wok"
	echo "done."
}

for arg in "$@"; do

	case "$arg" in
		-*=*) argval=`echo "$arg" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
		*) argval="" ;;
	esac

	case "$arg" in
		-h|--help)         usage; exit 0;;
		install)           action=install;;
		reinstall)         action=reinstall;;
		remove)            action=uninstall;;
		purge)             action=purge;;
		--user)            req_root=false;;
		--install-path=*)  install_path="$argval";;
		--bin-path=*)      bin_path="$argval";;
		--conf-path=*)     conf_path="$argval";;
		--data-path=*)     data_path="$argval";;
		*) echo "Unknown argument '$arg'" >&2; exit 1;;
	esac
done

   test -z "$install_path" \
|| test -z "$bin_path" \
|| test -z "$conf_path" \
|| test -z "$data_path" \
&& usage >&2 && exit 1

$action
exit $?
