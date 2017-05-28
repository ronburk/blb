#!/bin/bash
#
# $1 - source directory containing blb library scripts
# $2 - name of test data file
# $3 - name of "pass" file we create to indicate success

source ${1:?}/blb-string.sh

mapfile -t  <${2:?}

# check dat file not empty
BLAssert '[ "${MAPFILE-NULL}" != "NULL" ]'

MaxLine=$(( ${#MAPFILE[@]} - 1 ))
echo "MaxLine = $MaxLine"
for (( iLine=1; iLine < MaxLine; iLine+=2 )); do
    Source="${MAPFILE[iLine]}"
    Expect="${MAPFILE[iLine+1]}"
    StrDequote Source
    if [ "$Source" != "$Expect" ]; then
        printf "'%s' became '%s'; expected '%s'\n" "${MAPFILE[iLine]}" "$Source" "$Expect"
        if [ "$Source" == "${MAPFILE[iLine]}" ]; then
            printf "Note that source string was unchanged.\n"
        fi
        exit 1
    fi
done

touch "${3:?}"
exit 0


