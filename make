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


echo ${RootDir}

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
        export BLBSRCDIR=$(pwd)
        for test in ./test/**/*.sh; do
            if ! bash "$test" ; then
                echo "$test: can't happen: script failed."
                exit 1
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
