#!/bin/bash
# Copyright (C) 2017 Ron Burk - All Rights Reserved.
#
# blb-core - core functions for Burk Labs Bash library
#
# 

# declare some global associative arrays
declare -A BLGlobalTraceStates BLGlobalTraceLeave

# Put initialization in function so you could forego it by
# commenting out one line, though I hope you do not.
#
function BLCoreInit(){
    # Settings we insist on
    # signal ERR when anything bad happens
    set -o errexit
    # catch uninitialized variables
    set -o nounset
    # catch failed pipes
    set -o pipefail

    # Define traps for tracebacks
    trap 'BLStackTrace' ERR
:    trap 'BLExitTrace'  EXIT

    # Want that trap on ERR inherited
    set -o errtrace

    # Make prompt show details
    export PS4='+(${BASH_SOURCE##*/}):${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

}


function BLTraceSet(){
    local -i Value="$1"
    shift
    # now $1 ... $N  contains the names of functions we will operate on
    while (( $# > 0 )); do
        BLGlobalTraceStates["$1"]="$Value"
        shift
    done;
    
}

function BLTraceOn(){
    # no arguments means force tracing for ALL participating functions
    if [[ $# == 0 ]]; then
        # pretend we were passed names of all participating functions
        set -- "${!BLGlobalTraceStates[@]}"
    fi
    BLTraceSet 1 "$@"
}

function BLTraceOff(){
    # no arguments means force tracing off for ALL participating functions
    if [[ $# == 0 ]]; then
        # pretend we were passed names of all participating functions
        set -- "${!BLGlobalTraceStates[@]}"
    fi
    BLTraceSet 0 "$@"
}

function BLTraceDisable(){
    # no arguments means disable tracing for ALL participating functions
    if [[ $# == 0 ]]; then
        # pretend we were passed names of all participating functions
        set -- "${!BLGlobalTraceStates[@]}"
    fi
    BLTraceSet '' "$@"
}

function BLCoreError(){
    echo "$@" >/dev/tty
    exit 1
}
function BLCoreEnter() {
    local -r CallerFuncName="${FUNCNAME[1]}"
    # if state not set, this will set it to empty string
    local -r TraceState="${BLGlobalTraceStates[$CallerFuncName]:=}"
    local    LeaveCode=":"
    
    # if caller is trace-enabled
    if ! [ -z "$TraceState" ]; then
        # if trace is currently ON
        if [ -o xtrace ]; then
            [ "$TraceState" -eq 0 ] && set +o xtrace
            LeaveCode="set -o xtrace"      # Remember to turn trace back on when caller returns
        # else if trace is currently OFF
        else
            [ "$TraceState" -eq 1 ] && set -o xtrace
            LeaveCode="set +o xtrace"      # Remember to turn trace back off when caller returns
        fi
    fi
    # store code that BLCoreLeave() just invoke for the caller
    BLGlobalTraceLeave[$CallerFuncName]="$LeaveCode"
} 2>/dev/null   # don't want to clutter xtrace output

function BLCoreLeave(){
    ${BLGlobalTraceLeave[${FUNCNAME[1]}]}
} 2>/dev/null


# BLStackTrace() - emit a stack trace
#



function BLStackTrace(){
    local -i StartFrame=0   # assume nobody wants to see *our* stack frame
    local -i iFrame=0 MaxFrame=${#FUNCNAME[@]} iArgc=0 iArgv=0

    # Logic will be simplified if we always walk the entire stack, even
    # if the caller wishes to omit one or more topmost stack frames.
    # 'StartFrame' is therefore where we actually start printing.
    if [ $# -gt 0 ]; then
        StartFrame="$1"    # default is to omit our own stack frame
    fi
    local HaveArgs="false"
    # if it is plausible that BASH_ARGC/V are set correctly
    if shopt -q extdebug && [[ ${#BASH_ARGC[@]} -eq $MaxFrame-1 ]];  then
        HaveArgs="true"
    fi

    echo "Filenames: ${BASH_SOURCE[*]}"
    echo "LineNums:  ${BASH_LINENO[*]}"
    echo "Functions: ${FUNCNAME[*]}"
    echo "BASH_ARGC: ${BASH_ARGC[*]}"
    echo "#BASH_ARGC: ${#BASH_ARGC[@]}"
    echo "MaxFrame= $MaxFrame"
    echo "BASH_ARGV: ${BASH_ARGV[*]}"
    echo "#BASH_ARGV: ${#BASH_ARGV[@]}"

    local -i MaxFilename=0 MaxLineNum=0
    for (( iFrame=StartFrame; iFrame < MaxFrame-1; ++iFrame )); do
        Filename="${BASH_SOURCE[iFrame+1]}"
        LineNum="${BASH_LINENO[iFrame]}"
        if (( ${#Filename} > MaxFilename )); then
            MaxFilename="${#Filename}"
        fi
        if (( ${#LineNum} > MaxLineNum )); then
            MaxLineNum="${#LineNum}"
        fi
    done
        
    local OldSource=""
    local -r SrcColorStart="$(tput setaf 1)$(tput setab 7)"
    local -r SrcColorStop="$(tput sgr 0)"
    for (( iFrame=0; iFrame < MaxFrame-1; ++iFrame )); do
        local Filename="${BASH_SOURCE[iFrame + 1]}"
        local LineNum="${BASH_LINENO[iFrame]}"
        local Function="${FUNCNAME[iFrame+1]}"
        local MaybeName="$Filename"
        if (( iFrame >= StartFrame )); then
            mapfile -t -s $((LineNum - 1)) -n 1 LineArray < "${Filename}"
            if [[ "$Filename" == "$OldSource" ]]; then
                MaybeName=" "
            else
                OldSource="$Filename"
            fi
            printf "%-*s#%*d %s%s%s\n" "$MaxFilename" "$MaybeName" "$MaxLineNum" "$LineNum" \
               "$SrcColorStart" "${LineArray[*]}" "$SrcColorStop"
            if read -r _ DefLine _ < <( declare -F "$Function" ); then
                LineNum=$DefLine
            elif [[ "$Function" == "source" ]]; then
                LineNum="${BASH_LINENO[iFrame+1]}"
                Filename="${BASH_SOURCE[iFrame+2]}"
            fi
            MaybeName="$Filename"
            if [[ "$Filename" == "$OldSource" ]]; then
                MaybeName=" "
            else
                OldSource="$Filename"
            fi
            if (( iFrame < MaxFrame-2 )); then
                printf "%-*s#%*d %s" "$MaxFilename" "$MaybeName" "$MaxLineNum" "$LineNum" "$Function"
            fi
        fi
        if $HaveArgs && (( iFrame < MaxFrame-2)) ; then
            local -i ArgCount=$(( BASH_ARGC[iArgc+1] ))
            while (( ArgCount-- > 0 )); do
                local Arg="${BASH_ARGV[$iArgv]}";
                case "$Arg" in  *[[:space:]]*|'') Arg="'$Arg'";  esac
                if (( iFrame >= StartFrame )); then
                    printf " %s" "$Arg"
                fi
                (( ++iArgv ))
            done
            (( ++iArgc ));
        fi
        printf "\n"
    done

    # if [[ $frame -eq 1 ]] ; then
    #     echo "??????????????????????????"
    #     caller_info=( $(caller 0) )
    #     echo ":: ${caller_info[2]}: Line ${caller_info[0]}: ${caller_info[1]}"
    # fi
}



# assertion functions
function BLAssert(){
    BLCoreEnter
    # no args means assert statement should not have been reached
    if [ $# -le 0 ]; then die "Assertion failed." ; fi
    # otherwise, die if assertion not true
    # shellcheck disable=SC2068
    if $@ ; then
        BLCoreLeave
    else
        DieMarker
        echo "Assertion failed: " "$@"
        local -ir end=${#BASH_SOURCE[@]}
        local -i i
        for ((i=1; i < end; ++i));
            do
            local -i linenum=${BASH_LINENO[(($i-1))]}
            echo "${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:$linenum"
            local Src="${BASH_SOURCE[$i]}"
            if test -r "$Src" -a -f "$Src" ; then
                # read line number of file
                mapfile -t -s $((linenum - 1)) -n 1 LineArray < "${Src}"
                echo "    ${LineArray[*]}"
            else
                echo "That's friggin weird. Source file [${Src}] not readable!"
            fi
            done
        Die
    fi
}

BLCoreInit
BLTraceOn BLCoreFunctionsInFile
#BLAssert "[ 1 -gt 3 ]"

