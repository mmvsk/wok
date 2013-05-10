#!/bin/bash

#
# Makes silent stdoutput...
#
# Usage:
#
# silent command
#

silent() {
	$* >> /dev/null
}
