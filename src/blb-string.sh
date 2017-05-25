#!/bin/bash
# Copyright (C) 2017 Ron Burk - All Rights Reserved.
#
# blb-string - string functions for Burk Labs Bash library
#

# shellcheck source=blb-core.sh
. "${BLGlobal["ROOTDIR"]:=${BASH_SOURCE[0]%/*}}/blb-core.sh"

# Strip outer quotes, reduce embeded double quotes. We never fail
# to do *something*. Messed up input string is caller's responsibility.
#
function StrDequote(){
    local -n StrDequote_In="$1"
    local -i iChar=0; Len="${#StrDequote_In}"
    local    Output="" qChar="" Char

    if [ "${StrDequote_In:0:1}" == "\"" ]; then
        qChar="\""
    elif [ "${StrDequote_In:0:1}" == "\'" ]; then
        qChar="\'"
    fi
    # if it's well-formed enough for us to care
    if [ -n "$qChar" ] && [ "$Len" -ge 2 ] && [ "$qChar" == "${StrDequote_In: -1}" ]; then
        # OK, we *are* going to modify the caller's string
        for (( iChar=1; iChar < Len; ++iChar )); do
            Char="${StrDequote_In:$iChar:1}"
            if [ "$Char" == "$qChar" ]; then
                # if we found matching close quote
                if (( iChar+1 >= Len )); then
                    break;
                # else if we found a doubled quote
                elif [ "$qChar" == "${StrDequote_In:iChar+1:1}" ]; then
                     Output+="$Char"; (( ++iChar ))
                fi
            fi
            Output+="$Char"
        done
        StrDequote_In="$Output"
    fi
}

