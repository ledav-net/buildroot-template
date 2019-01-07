#!/bin/bash

[ -z "$BR2_CONFIG" -o -z "$TARGET_DIR" -o -z "$HOST_DIR" ] && \
    die "Mandatory environment missing !"

MAINDIR=$(sed -n 's/BR2_DEFCONFIG="\(.*_defconfig\)"/\1/ p' < "$BR2_CONFIG")
MAINDIR=$(readlink -f "${MAINDIR%/*}/..")

. "$MAINDIR"/scripts/include/log || exit 1

[ -z "$1" ] && die "$0 <ELF binary>"

BIN="$1"
READELF=$(echo "$HOST_DIR"/usr/bin/*-buildroot-linux-*-readelf)
[ -n "$CROSS_LD_LIBRARY_PATH" ] || CROSS_LD_LIBRARY_PATH=".:lib:lib64:usr/lib"

[ -x "$READELF" ] || die "Failed to find a suitable readelf executable !"
[ -e "$BIN" ]     || die "File not found !"

LINKED_LIBS=

function trace_lib {
    local bin="$1"
    local libs ints found

    # Search for NEEDED libraries
    libs=$("$READELF" -d "$bin" | grep NEEDED | sed -re 's/.*Shared library:[[:space:]]+\[([^]]+)\].*/\1/;')
    # Also search for 'program interpreter' dependancy...
    ints=$("$READELF" -l "$bin" | sed -nre 's/.*\[Requesting program interpreter:[[:space:]]+\/?([^]]+)\].*/\1/ p;')

    for lib in $libs $ints; do
        found=0
        for libpath in $(echo "$CROSS_LD_LIBRARY_PATH" | tr : "\n"); do
            if [ -e "$libpath/$lib" ]; then
                found=1
                LINKED_LIBS+="$libpath/$lib\n"
                trace_lib "$libpath/$lib"
                break
            fi
        done
        [ "$found" -eq 0 ] && warn "$lib => not found"
    done
}

BIN=$(readlink -f "$BIN")
cd "$TARGET_DIR" || die "Cannot change dir to '$TARGET_DIR'"
trace_lib "$BIN"
echo -en "$LINKED_LIBS" | sort -u
