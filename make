#!/bin/bash

function Syntax(){
    printf "./make [test|check|install|clean]\n"
    exit 1
}

RootDir=$(cd $(dirname "$BASH_SOURCE") && pwd)
if ! [ -f "$RootDir/make" ]; then
    printf "Can't establish root directory.\n"
    exit
fi

function RunTest(){
    local -r TestScript="$1"
    local -r SourceDir="$2"
    local -r TestData="$3"
    local -r PassFIle="$4"

    local Options=""
    if [[ $- =~ x ]]; then
        Options="-x"
    fi

    rm -f "$PassFile"
    if ! bash $Options $TestScript $SourceDir $TestData $PassFile; then
        printf "%s: test script died!\n" "$TestScript"
        exit 1
    else
        if [ -f "$PassFile" ]; then
            printf "Pass: "
        else
            printf "FAIL: "
        fi
    fi
    printf "%s\n" "${TestData}"
}

if [ $# -ne 1 ]; then
    Syntax
fi

case "$1" in
    test)
        shopt -s globstar
        shift
        if [ $# -ge 0 ]; then
            case "$1" in
                *)
                    ;;
            esac
        fi
        # test framework is simple:
        # 1) execute every shell script (.sh)
        # 2) every unique test must have corresponding .dat file
        # 3) every test that passes must create corresponding .pass file
        # 4) report which tests failed.
        SourceDir="$PWD/src"
        for TestScript in test/**/*.sh; do
            TestDir="${TestScript%.sh}"
            FileBase="${Dir%.*}"
            TestData="${TestDir}.dat"
            PassFile="${TestData/%.dat/.pass}"
            if [ -d "$TestDir" ]; then
                for TestData in $TestDir/*.dat; do
                    PassFile="${TestData/%.dat/.pass}"
                    RunTest "$TestScript" "$SourceDir" "$TestData" "$PassFile"
                done
            elif [ -f "$TestData" ]; then
                bash $TestScript $SourceDir $TestData $PassFile
                RunTest "$TestScript" "$SourceDir" "$TestData" "$PassFile"
            fi
        done
        ;;
    check)
        GLOBIGNORE="test.sh"
        pushd $RootDir/src
        ~/.cabal/bin/shellcheck -x $RootDir/src/*.sh
        unset GLOBIGNORE
        popd
        ;;
    install)
        echo install
        ;;
    clean)
        find $RootDir '*.pass' -delete
        ;;
    *)
        Syntax
        ;;
esac
