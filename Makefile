
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

#
# Used to configure Wok.
#
# Example: make install wok_path=/usr/share/wok \
#                       sbin_path=/usr/sbin/wok \
#                       conf_path=/etc/wok \
#                       repo_path=/var/lib/wok
#
wok_path  = /usr/local/share/wok
sbin_path = /usr/local/sbin/wok
conf_path = /usr/local/etc/wok
repo_path = /var/local/lib/wok

shitify = 1

# Don't change!
SHELL = sh

modules     = $(basename $(notdir $(wildcard src/modules/*.bash)))
modules_src = $(wildcard src/modules/*.bash)
modules_ini = $(wildcard src/modules/*.ini)
common_src  = $(wildcard src/common/*.bash)

#-----------------------------------------------------------------------
# Commands
#-----------------------------------------------------------------------

default: wok

check:
	@echo list: $(modules)
	@echo src:  $(modules_src)

test: wok
	@for f in $(wildcard test/unit/*); do \
		name=`basename "$$f"`; \
		echo "*** $${name}"; \
		"$$f" || exit 1; \
		echo; \
	done
	@echo "All tests passed successfully!"

clean:
	@echo -n "Cleaning..."
	@-rm -rf dist/*
	@echo "done."

install: wok
	@./install.sh \
		--install \
		--wok-path="$(wok_path)" \
		--sbin-path="$(sbin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

uninstall:
	@./install.sh \
		--uninstall \
		--wok-path="$(wok_path)" \
		--sbin-path="$(sbin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

purge:
	@./install.sh \
		--purge \
		--wok-path="$(wok_path)" \
		--sbin-path="$(sbin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

hostconfig:
	@test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/sbin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	@$${EDITOR:-vi} /usr/local/etc/wok/config

.PHONY: default test clean install uninstall purge hostconfig

#-----------------------------------------------------------------------
# Targets
#-----------------------------------------------------------------------

wok: \
dist/wok \
dist/repo \
dist/conf \
dist/wok/wok \
dist/conf/wok.ini \
dist/wok/util \
dist/wok/util/str_match \
dist/wok/util/str_slugify \
dist/wok/util/ini_get \
dist/wok/util/json_set \
dist/wok/util/json_get

.PHONY: wok

#-----------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------

# $@: target
# $*: target basename
# $<: first dep
# $^: all deps
# $?: more recent deps

dist/wok dist/wok/util dist/conf dist/modules:
	@echo -n "Creating directory $@..."
	@mkdir -p "$@"
	@echo "done."

dist/repo:
	@echo -n "Creating empty repository..."
	@cp -r res/repo dist/repo
	@echo "done."

dist/wok/util/str_match: src/util/str_match.php
	@echo -n "Building $@..."
	@(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@"
	@echo "done."

dist/wok/util/str_slugify: src/util/str_slugify.php
	@echo -n "Building $@..."
	@(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@"
	@echo "done."

dist/wok/util/ini_get: src/util/ini_get.php
	@echo -n "Building $@..."
	@(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@"
	@echo "done."

dist/wok/util/json_get: src/util/json_get.php
	@echo -n "Building $@..."
	@(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@"
	@echo "done."

dist/wok/util/json_set: src/util/json_set.php
	@echo -n "Building $@..."
	@(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@"
	@echo "done."

dist/conf/wok.ini: src/wok.ini $(modules_ini)
	@echo -n "Assembling $@..."
	@cp src/wok.ini "$@"
	@$(foreach path,$(modules_ini),cat $(path) >>"$@";)
	@echo "done."

dist/wok/wok: src/*.bash $(common_src) $(modules_src)
	@echo -n "Building $@..."
	@(echo "#!/bin/bash"; cat src/wok.bash) >"$@" && chmod +x "$@"
	@sed -i 's/{{wok_module_list}}/$(foreach module,$(modules),"$(module)")/g' "$@"
	@sed -i 's:{{wok_config_file}}:"$(conf_path)/wok.ini":g' "$@"
	@sed -i 's:{{wok_repo_path}}:"$(repo_path)":g' "$@"
	@sed -i 's:{{wok_util_path}}:"$(wok_path)/util":g' "$@"
	@sed -i "/{{modules_src}}/{`printf '$(foreach path,$(modules_src),r $(path)\n)d'`}" "$@"
	@sed -i "/{{common_src}}/{`printf '$(foreach path,$(common_src),r $(path)\n)d'`}" "$@"
	@sed -i "/{{wok_module_src}}/{`printf 'r src/wok_module.bash\nd'`}" "$@"
	@sed -i "/{{wok_config_src}}/{`printf 'r src/wok_config.bash\nd'`}" "$@"
	@sed -i "/{{wok_repo_src}}/{`printf 'r src/wok_repo.bash\nd'`}" "$@"
	@sed -i "/{{wok_domain_src}}/{`printf 'r src/wok_domain.bash\nd'`}" "$@"
	@sed -i "/{{wok_report_src}}/{`printf 'r src/wok_report.bash\nd'`}" "$@"
	@sed -i '22,$${/^#/d;}' "$@"
ifeq ($(shitify), 1)
	@sed -i '22,$${/^$$/d;}' "$@"
	@sed -i 's/^\s\+//g' "$@"
endif
	@echo "done."
