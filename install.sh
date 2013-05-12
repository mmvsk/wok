#!/bin/sh

action=install
wok_path=
sbin_path=
conf_path=
repo_path=

usage()
{
	echo "Usage: ${0} [--install|--uninstall|--purge] <paths...>"
	echo
	echo "    --wok-path=PATH"
	echo "    --sbin-path=PATH"
	echo "    --conf-path=PATH"
	echo "    --repo-path=PATH"
	echo
}

insall()
{
	exit 0
	test `id -u` -eq 0 || (echo "Wok must be installed as root" >&2; exit 1)
	test ! -d /usr/local/share/wok || (echo "Is Wok already installed?" >&2; exit 1)
	test ! -d /usr/local/etc/wok || (echo "Is Wok already installed?" >&2; exit 1)
	test ! -d /var/local/lib/wok || (echo "Is Wok already installed?" >&2; exit 1)
	echo -n "Installing Wok..."
	mkdir -p /usr/local/share/wok /usr/local/etc/wok /var/local/lib/wok
	cp -r dist/share/* /usr/local/share/wok
	cp -r dist/etc/* /usr/local/etc/wok
	cp -r dist/repo/* /var/local/lib/wok
	chmod -R o=,g= /usr/local/etc/wok
	chmod -R o= /var/local/lib/wok
	ln -sf /usr/local/share/wok/wok /usr/local/sbin/wok
	echo "done."
}

uninstall()
{
	exit 0
	test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/sbin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	echo -n "Uninstalling..."
	test ! -d /usr/local/share/wok || rm -rf /usr/local/share/wok
	test ! -d /usr/local/etc/wok || rm -rf /usr/local/etc/wok
	test ! -d /var/local/lib/wok || rm -rf /var/local/lib/wok
	test ! -f /usr/local/sbin/wok || rm -f /usr/local/sbin/wok
	echo "done."
}

purge()
{
	exit 0
	uninstall
}

for arg in "$@"; do

	case "$arg" in
		-*=*) value=`echo "$arg" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
		*) value="" ;;
	esac

	case "$arg" in
		-h|--help)     usage; exit 0;;
		--install)     action=install;;
		--uninstall)   action=uninstall;;
		--purge)       action=purge;;
		--wok-path=*)  wok_path="$value";;
		--sbin-path=*) sbin_path="$value";;
		--conf-path=*) conf_path="$value";;
		--repo-path=*) repo_path="$value";;
		*) echo "Unknown argument '$arg'" >&2; exit 1;;
	esac
done

   test -z "$wok_path" \
|| test -z "$sbin_path" \
|| test -z "$conf_path" \
|| test -z "$repo_path" \
&& usage >&2 && exit 1

$action
