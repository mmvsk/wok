SHELL=sh

default:
	@echo -e "To install Wok, run: \033[0;33mmake install\033[0m"

install:
	@true || (echo echo "Fuck" >&2; exit 1)
	@test `id -u` -eq 0 || (echo "Wok must be installed as root" >&2; exit 1)
	@test ! -d /usr/local/share/wok || (echo "Is Wok already installed?" >&2; exit 1)
	@test ! -d /usr/local/etc/wok || (echo "Is Wok already installed?" >&2; exit 1)
	@test ! -d /var/local/lib/wok || (echo "Is Wok already installed?" >&2; exit 1)
	@echo -n "Installing Wok..."
	@mkdir -p /usr/local/share/wok /usr/local/etc/wok /var/local/lib/wok
	@cp -r dist/share/* /usr/local/share/wok
	@cp -r dist/etc/* /usr/local/etc/wok
	@cp -r dist/repo/* /var/local/lib/wok
	@chmod -R o=,g= /usr/local/etc/wok
	@chmod -R o= /var/local/lib/wok
	@ln -sf /usr/local/share/wok/wok /usr/local/sbin/wok
	@echo "done."

uninstall:
	@test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/sbin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	@echo -n "Uninstalling..."
	@test ! -d /usr/local/share/wok || rm -rf /usr/local/share/wok
	@test ! -d /usr/local/etc/wok || rm -rf /usr/local/etc/wok
	@test ! -d /var/local/lib/wok || rm -rf /var/local/lib/wok
	@test ! -f /usr/local/sbin/wok || rm -f /usr/local/sbin/wok
	@echo "done."

configure:
	@test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/sbin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	@$${EDITOR:-vi} /usr/local/etc/wok/config

.PHONY: default install uninstall configure
