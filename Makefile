
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

#TODO: build <with sharedir=,etcdir=,...>, config, test, install,
#TODO: (...) hostconfig, uninstall

#-----------------------------------------------------------------------
# Configuration
#-----------------------------------------------------------------------

SHELL=sh

#-----------------------------------------------------------------------
# Commands
#-----------------------------------------------------------------------

default: dist

dist: util wok modules

test: dist
	@for f in $(wildcard test/*); do \
		name=`basename "$$f"`; \
		echo "*** $${name}"; \
		"$$f" || exit; \
		echo; \
	done
	@echo "All tests passed successfully!"

clean:
	-rm -rf dist/*

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

config:
	@test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/sbin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	@$${EDITOR:-vi} /usr/local/etc/wok/config

hostconfig:

.PHONY: default dist test clean install uninstall config hostconfig

#-----------------------------------------------------------------------
# Targets
#-----------------------------------------------------------------------

util: \
dist/util \
dist/util/str_match \
dist/util/str_slugify \
dist/util/ini_get

wok:

modules:

.PHONY: util wok modules

#-----------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------

# $@: target
# $*: target basename
# $<: first dep
# $^: all deps
# $?: more recent deps

dist/util:
	mkdir -p "$@"

dist/util/str_match: src/util/str_match.php
	(echo '#!/usr/bin/php'; cat "$<") >"$@" && chmod +x "$@"

dist/util/str_slugify: src/util/str_slugify.php
	(echo '#!/usr/bin/php'; cat "$<") >"$@" && chmod +x "$@"

dist/util/ini_get: src/util/ini_get.php
	(echo '#!/usr/bin/php'; cat "$<") >"$@" && chmod +x "$@"
