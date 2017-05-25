#!/bin/bash

echo "Version=${BASH_VERSION}"
#shopt -s extdebug

declare -A BLGlobal
# shellcheck source=blb-core.sh
. "${BLGlobal["ROOTDIR"]=${BASH_SOURCE[0]%/*}}/blb-core.sh"
declare -p BLGlobal
echo "foo=${BLGlobal["ROOTDIR"]}"
# shellcheck source=blb-string.sh
. "${BLGlobal["ROOTDIR"]}/blb-string.sh"

BLAssert "[ $# -gt 0 ]"
