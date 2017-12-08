
#
# Copyright © 2013-2015 Max Ruman <rmx@guanako.be>
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
#                       bin_path=/usr/bin/wok \
#                       conf_path=/etc/wok \
#                       repo_path=/var/lib/wok
#
wok_path  = /usr/local/share/wok
bin_path = /usr/local/bin/wok
conf_path = /usr/local/etc/wok
repo_path = /var/local/lib/wok

# No questions :)
shitify = 1

# Make options (don't touch!)
SHELL = /bin/bash
.SILENT:

modules     = $(basename $(notdir $(wildcard src/modules/*.bash)))
modules_src = $(wildcard src/modules/*.bash)
modules_ini = $(wildcard src/modules/*.ini)
common_src  = $(wildcard src/common/*.bash)

# Version file generator
ver_file = Version
ver = $(shell                                                  \
	test -d .git || (echo "null"; exit 1) || exit 2>/dev/null;   \
	git describe --always | perl -pe "s/^v//" | (                \
		[[ "$(env)" == "debug" ]]                                  \
			&& perl -pe "s/^(\d+\.\d+\.\d+)$$|(-\d+-)/\$$1-dev\$$2/" \
			|| cat                                                   \
	)                                                            \
)

#
# Call a build unit
#
# Characters: … ✓✔ ✗✘
#
# @param string  The name of the build
# @param command The command to execute
# @param command The command to execute in case of failure
#
define task
	op="$$(echo $1 | sed -e 's/^ *//' -e 's/ *$$//')";  \
	echo -n "… $$op";                                   \
		r=$$(( $2 ) 3>&1 1>&2 2>&3)                       \
			&& echo -e "\r\e[1;32m✔\e[0m $$op"              \
			|| ($3;                                         \
				echo -e "\r\e[1;31m✘\e[0m $$op\n";            \
				echo "$$r" | sed "s:^:\x1b[0;31m  >\x1b[0m :g"; \
				echo;                                         \
				exit 1                                        \
			)
endef

#-----------------------------------------------------------------------
# Commands
#-----------------------------------------------------------------------

default: wok.bash $(ver_file)

elf: wok.elf

wok.bash: dist/wok/wok.bash
	test ! -f dist/wok/wok.elf || $(MAKE) wok.elf

wok.elf: dist/wok/wok.bash dist/wok/wok.elf

test: wok
	for f in $(wildcard test/unit/*); do \
		name=$$(basename "$$f"); \
		echo "*** $${name}"; \
		"$$f" || exit 1; \
		echo; \
	done
	echo -e "\e[1;32m✔\e[0m All tests passed successfully!"

check:
	echo list: $(modules)
	echo src:  $(modules_src)

clean:
	$(call task, "Cleaning previous build", \
		rm -rf dist/* || true;                \
		rm -f $(ver_file) || true             \
	, true)

install: wok
	./install.sh \
		--install \
		--wok-path="$(wok_path)" \
		--bin-path="$(bin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

uninstall:
	./install.sh \
		--uninstall \
		--wok-path="$(wok_path)" \
		--bin-path="$(bin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

reinstall: wok
	./install.sh \
		--reinstall \
		--wok-path="$(wok_path)" \
		--bin-path="$(bin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

purge:
	./install.sh \
		--purge \
		--wok-path="$(wok_path)" \
		--bin-path="$(bin_path)" \
		--conf-path="$(conf_path)" \
		--repo-path="$(repo_path)"

hostconfig:
	test -d /usr/local/share/wok \
		|| test -d /usr/local/etc/wok \
		|| test -d /var/local/lib/wok \
		|| test -f /usr/local/bin/wok \
		|| (echo "Wok is not installed on this system" >&2; exit 1)
	$${EDITOR:-vi} /usr/local/etc/wok/config

.PHONY: \
default \
wok.bash \
wok.elf \
elf \
test \
check \
clean \
install \
uninstall \
reinstall \
purge \
hostconfig

#-----------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------

# $@: target
# $*: target basename
# $<: first dep
# $^: all deps
# $?: more recent deps

dist/wok dist/wok/util dist/conf dist/modules:
	$(call task, "Creating directory $@", mkdir -p "$@", true)

dist/repo:
	$(call task, "Creating empty repository",          \
		mkdir -p "$@";                                   \
		mkdir "$@/modules";                              \
		touch "$@/domain.index";                         \
		for module in $(modules); do                     \
			mkdir -p dist/repo/modules/$$module/index;     \
			mkdir -p dist/repo/modules/$$module/data;      \
			touch dist/repo/modules/$$module/domain.index; \
		done                                             \
	, true)

dist/wok/wok.elf: dist/wok/wok.bash
	$(call task, "Compiling dist/wok/wok.elf", \
		shc -r -T -f dist/wok/wok.bash;          \
		mv dist/wok/wok.bash.x dist/wok/wok.elf; \
		rm -f dist/wok/wok.bash.x.c || true;     \
	, true)

dist/wok/util/str_match: src/util/str_match.php
	$(call task, "Building $@",                                \
		(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@" \
	, true)

dist/wok/util/str_slugify: src/util/str_slugify.php
	$(call task, "Building $@",                                \
		(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@" \
	, true)

dist/wok/util/ini_get: src/util/ini_get.php
	$(call task, "Building $@",                                \
		(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@" \
	, true)

dist/wok/util/json_get: src/util/json_get.php
	$(call task, "Building $@",                                \
		(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@" \
	, true)

dist/wok/util/json_set: src/util/json_set.php
	$(call task, "Building $@",                                \
		(echo "#!/usr/bin/php"; cat "$<") >"$@" && chmod +x "$@" \
	, true)

dist/conf/wok.ini: src/wok.ini $(modules_ini)
	$(call task, "Assembling $@",                                \
		cp src/wok.ini "$@";                                       \
		$(foreach path,$(modules_ini),(echo; cat $(path)) >>"$@";) \
	, true)

# Do not add dist/wok, because dist/wok/util already use it
dist/wok/wok.bash: \
dist/repo \
dist/conf \
dist/conf/wok.ini \
dist/wok/util \
dist/wok/util/str_match \
dist/wok/util/str_slugify \
dist/wok/util/ini_get \
dist/wok/util/json_set \
dist/wok/util/json_get \
$(common_src) \
$(modules_src) \
src/*.bash
	$(call task, "Building $@",                                                                \
		(echo "#!/bin/bash"; cat src/wok.bash) >"$@" && chmod +x "$@";                           \
		sed -i 's:{{wok_version}}:"$(ver)":g' "$@";                                      \
		sed -i 's/{{wok_module_list}}/$(foreach module,$(modules),"$(module)")/g' "$@";          \
		sed -i 's:{{wok_config_file}}:"$(conf_path)/wok.ini":g' "$@";                            \
		sed -i 's:{{wok_repo_path}}:"$(repo_path)":g' "$@";                                      \
		sed -i 's:{{wok_util_path}}:"$(wok_path)/util":g' "$@";                                  \
		sed -i "/{{modules_src}}/{`printf '$(foreach path,$(modules_src),r $(path)\n)d'`}" "$@"; \
		sed -i "/{{common_src}}/{`printf '$(foreach path,$(common_src),r $(path)\n)d'`}" "$@";   \
		sed -i "/{{wok_module_src}}/{`printf 'r src/wok_module.bash\nd'`}" "$@";                 \
		sed -i "/{{wok_config_src}}/{`printf 'r src/wok_config.bash\nd'`}" "$@";                 \
		sed -i "/{{wok_repo_src}}/{`printf 'r src/wok_repo.bash\nd'`}" "$@";                     \
		sed -i "/{{wok_domain_src}}/{`printf 'r src/wok_domain.bash\nd'`}" "$@";                 \
		sed -i "/{{wok_report_src}}/{`printf 'r src/wok_report.bash\nd'`}" "$@";                 \
	, true)
ifeq ($(shitify), 1)
	# Obfuscation process
	sed -i '22,$${/^#/d;}' "$@"
	sed -i '22,$${/^$$/d;}' "$@"
	sed -i 's/^\s\+//g' "$@"
endif

$(ver_file):
ifneq ($(shell cat $(ver_file) 2>/dev/null || true), $(ver))
	$(call task, "$(ver_file): $(ver)", echo "$(ver)" > $@, true)
endif

.PHONY: $(ver_file)
