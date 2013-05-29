
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

WOK_REPORT_MAIL_CMD="mailx"

#
# Create a report.
#
# Usage: wok_report_create <report:ref>
#
wok_report_create()
{
	local __report_ref="$1"
	local __report

	if ! __report="$(mktemp)"; then
		return 1
	fi
	printf -v "$__report_ref" %s "$__report"
}

#
# Delete a report
#
# Usage: wok_report_delete <report:ref>
#
wok_report_delete()
{
	local report="${!1}"

	[[ ! -f $report ]] && return 1

	rm "$report"
}

#
# Insert a line to a report.
#
# Usage #1: wok_report_insl <report:ref> <format:string> [<arg_1:string> .. <arg_n:string>]
# Usage #2: echo <line:string> | wok_report_insl <report:ref>
#
wok_report_insl()
{
	local report="${!1}"; shift
	local format
	local args
	local line

	[[ ! -f $report ]] && return 1

	if [[ $# -ge 1 ]]; then
		format="$1"; shift
		args=("$@")
		printf "$format\n" "${args[@]}"
	else
		while read line; do
			echo "$line"
		done
	fi >>"$report"
}

#
# Print a report to stdout or to a file
#
# Usage: wok_report_print <report:ref> [<filename:string>]
#
wok_report_print()
{
	local report="${!1}"
	local file="$2"

	[[ ! -f $report ]] && return 1

	if [[ -n "$file" ]]; then
		cp "$report" "$file"
	else
		cat "$report"
	fi
}

#
# Send a report by e-mail (using the mailx command).
#
# Usage: wok_report_send <report:ref> <email_to¹> [<subject>] [<email_from>]
#
wok_report_send()
{
	local report="${!1}"
	local email_to="$2"
	local subject="$3"
	local email_from="$4"
	local mailx_param=()

	[[ ! -f $report ]] && return 1
	[[ $# -lt 2 ]] && return 1

	[[ -n "$subject" ]]    && mailx_param=("${mailx_param[@]}" -s "$subject")
	#[[ -n "$email_from" ]] && mailx_param=("${mailx_param[@]}" -r "$email_from")
	[[ -n "$email_from" ]] && mailx_param=("${mailx_param[@]}" -a "From: ${email_from}")

	# Requires BSD mailx!
	"$WOK_REPORT_MAIL_CMD" "${mailx_param[@]}" "$email_to" <"$report"
}
