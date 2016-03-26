#!/bin/bash
#  File: fixnames.sh
#  Author: simplex
#  Created: 2016-03-26
#  Last Update: 2016-03-26
#  Notes:

PRE=scripts/betterconsole/lib/
SUF='\.lua'

for libf in scripts/betterconsole/lib/*.lua; do
	m=$(echo "$libf" | sed -e "s|^${PRE}\(.*\)${SUF}\$|\\1|")

	for f in $(find . -name '*.lua'); do
		sed -i -e "s/betterconsole.$m/betterconsole.lib.$m/g" "$f"
	done
done
