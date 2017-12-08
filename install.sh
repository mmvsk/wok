#!/bin/bash

base="`dirname "$0"`"
action=install
req_root=true
wok_path=/usr/local/share/wok
bin_path=/usr/local/bin/wok
conf_path=/usr/local/etc/wok
repo_path=/var/local/lib/wok

usage()
{
	echo "Usage: ${0} [--install|--uninstall|--reinstall|--purge]"
	echo "                    [--no-root]  <paths...>"
	echo
	echo "    --wok-path=<path>  (e.g. /usr/local/share/wok)"
	echo "    --bin-path=<path> (e.g. /usr/local/bin/wok)"
	echo "    --conf-path=<path> (e.g. /usr/local/etc/wok)"
	echo "    --repo-path=<path> (e.g. /var/local/lib/wok)"
	echo
}

install()
{
	local wok="${bin_path}/wok"
	local wok_elf="${wok_path}/wok.elf"
	local wok_bash="${wok_path}/wok.bash"

	if $req_root && test `id -u` -ne 0; then
		echo "Wok must be installed as root." >&2
		return 1
	fi
	if test -d "$wok_path"; then
		echo "Is Wok already installed?" >&2
		return 1
	fi
	echo -n "Installing Wok..."
	cp -r "$base"/dist/wok "$wok_path"
	test ! -d "$conf_path" && cp -r "$base"/dist/conf "$conf_path"
	test ! -d "$repo_path" && cp -r "$base"/dist/repo "$repo_path"
	chmod -R o=,g= "$conf_path"
	chmod -R o= "$repo_path"
	test -f "$wok_elf"
		&& ln -sf "$wok_elf" "$wok"
		|| ln -sf "$wok_bash" "$wok"
	echo "done."
}

uninstall()
{
	if test ! -d "$wok_path" && test ! -f "$bin_path"; then
		echo "Wok is not installed on this system" >&2
		return 1
	fi
	echo -n "Uninstalling..."
	rm -rf "$wok_path"
	rm -f "$bin_path"
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
	if test ! -d "$conf_path" &&  test ! -d "$repo_path"; then
		echo "Wok is not configured on this system" >&2
		return 1
	fi
	echo -n "Purging..."
	rm -rf "$conf_path"
	rm -rf "$repo_path"
	echo "done."
}

for arg in "$@"; do

	case "$arg" in
		-*=*) argval=`echo "$arg" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
		*) argval="" ;;
	esac

	case "$arg" in
		-h|--help)     usage; exit 0;;
		--install)     action=install;;
		--uninstall)   action=uninstall;;
		--reinstall)   action=reinstall;;
		--purge)       action=purge;;
		--no-root)     req_root=false;;
		--wok-path=*)  wok_path="$argval";;
		--bin-path=*) bin_path="$argval";;
		--conf-path=*) conf_path="$argval";;
		--repo-path=*) repo_path="$argval";;
		*) echo "Unknown argument '$arg'" >&2; exit 1;;
	esac
done

   test -z "$wok_path" \
|| test -z "$bin_path" \
|| test -z "$conf_path" \
|| test -z "$repo_path" \
&& usage >&2 && exit 1

$action
exit $?
