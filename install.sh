#!/bin/sh

base="`dirname "$0"`"
action=install
req_root=true
wok_path=
sbin_path=
conf_path=
repo_path=

usage()
{
	echo "Usage: ${0} [--install|--uninstall|--reinstall|--purge]"
	echo "                    [--no-root]  <paths...>"
	echo
	echo "    --wok-path=<path>  (e.g. /usr/local/share/wok)"
	echo "    --sbin-path=<path> (e.g. /usr/local/sbin/wok)"
	echo "    --conf-path=<path> (e.g. /usr/local/etc/wok)"
	echo "    --repo-path=<path> (e.g. /var/local/lib/wok)"
	echo
}

install()
{
	if $req_root && test `id -u` -ne 0; then
		echo "Wok must be installed as root." >&2
		return 1
	fi
	if test -d "$wok_path"; then
		echo "Is Wok already installed?" >&2
		return 1
	fi
	echo -n "Installing Wok..."
	mkdir -p "$wok_path" "$conf_path" "$repo_path"
	cp -r "$base"/dist/wok/* "$wok_path"
	test ! -d "$conf_path" && cp -r "$base"/dist/etc/* "$conf_path"
	test ! -d "$repo_path" && cp -r "$base"/dist/repo/* "$repo_path"
	chmod -R o=,g= "$conf_path"
	chmod -R o= "$repo_path"
	ln -sf "${wok_path}/wok" "$sbin_path"
	echo "done."
}

uninstall()
{
	if test ! -d "$wok_path" && test ! -f "$sbin_path"; then
		echo "Wok is not installed on this system" >&2
		return 1
	fi
	echo -n "Uninstalling..."
	rm -rf "$wok_path"
	rm -f "$sbin_path"
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
	echo -n "Purging"
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
		--sbin-path=*) sbin_path="$argval";;
		--conf-path=*) conf_path="$argval";;
		--repo-path=*) repo_path="$argval";;
		*) echo "Unknown argument '$arg'" >&2; exit 1;;
	esac
done

   test -z "$wok_path" \
|| test -z "$sbin_path" \
|| test -z "$conf_path" \
|| test -z "$repo_path" \
&& usage >&2 && exit 1

$action
exit $?
