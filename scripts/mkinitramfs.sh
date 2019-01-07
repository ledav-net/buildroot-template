#!/bin/bash

[ -z "$BR2_CONFIG" -o -z "$BUILD_DIR" -o -z "$TARGET_DIR" -o -z "$HOST_DIR" ] || \
[ -z "$BINARIES_DIR" -o -z "$O" ] && \
    die "Mandatory environment missing !"

MAINDIR=$(sed -n 's/BR2_DEFCONFIG="\(.*_defconfig\)"/\1/ p' < "$BR2_CONFIG")
MAINDIR=$(readlink -f "${MAINDIR%/*}/..")

. "$MAINDIR"/scripts/include/log || exit 10

INITRAMFSDIR="$BUILD_DIR"/initramfs
CROSSLDD="$MAINDIR"/scripts/crossldd.sh

if [ -x "$HOST_DIR"/sbin/modinfo ]; then
    MODINFO="$HOST_DIR"/sbin/modinfo
else
    MODINFO=$(which modinfo)
    [ -z "$MODINFO" ] && die "Need the 'modinfo' tool ..."
fi

# --copyover: Copy over initramfs directory if it already exist.
copyover=0
if [ "$1" == "--copyover" ]; then
    copyover=1
    shift
fi

# File to generate
INITRAMFSFILE="$BINARIES_DIR"/initramfs
KERNELVERSION=$(ls "$TARGET_DIR"/lib/modules | tail -1)
[ -z "$KERNELVERSION" ] && die "Cannot guess the kernel version to be installed ..."

#####################
### Configuration ###
#####################
# Note: Paths below are all relative to $TARGET_DIR

# Kernel modules (dep auto-detected & copied)
MODS=""
# Libraries (dep links auto-detected & copied)
LIBS=""
# Binaries (dep libraries auto-detected & copied)
BINS=""
# Files & Directories to copy (recursively)
COPY=""
# Directories to create
DIRS=""
# Compression to use
COMPRESSION="gzip"

## NETWORK DRIVERS ##
#MODS+=" e1000 e1000e igb r8169"

## NFS DRIVERS ##
#MODS+=" nfsv2 nfsv3"

## BUSYBOX ##
BINS+=" bin/busybox"

## SYSTEMD-UDEV ##
#COPY+=" lib/udev etc/udev"
#DIRS+=" lib/systemd"
#BINS+=" lib/systemd/systemd-udevd bin/udevadm"

## PLYMOUTH SPLASH SCREEN ##
#PLYMOUTH_LIBS="lib/libply.so.4 lib/libply-splash-core.so.4 usr/lib/libply-boot-client.so.4"
#PLYMOUTH_LIBS+=" usr/lib/libply-splash-graphics.so.4 usr/lib/libdrm.so.2"
#PLYMOUTH_COPY="var/lib/plymouth/boot-duration usr/lib/plymouth etc/plymouth"
#PLYMOUTH_COPY+=" usr/share/plymouth/themes/tribar"
#PLYMOUTH_COPY+=" usr/share/plymouth/themes/text"
#PLYMOUTH_COPY+=" usr/share/plymouth/themes/details"
#PLYMOUTH_COPY+=" usr/share/plymouth/themes/script"
#PLYMOYTH_DIRS="run/plymouth var/lib/plymouth"
#LIBS+=" $PLYMOUTH_LIBS"
#COPY+=" $PLYMOUTH_COPY"
#BINS+=" sbin/plymouthd bin/plymouth"

# End #############

function copy_library_with_symlinks {
    if [ -f "lib/$(basename $1)" ]; then
        return # already added
    elif [ -L "$1" ]; then
        cp -a "$1" "lib/"
        copy_library_with_symlinks "$(readlink -f "$1")"
    elif [ -f "$1" ]; then
        cp -a "$1" "lib/"
    else
        err "Lib $1 not found"
    fi
}

function add_library {
    local lib="$1"
    copy_library_with_symlinks "$TARGET_DIR/$lib"
    # install library dependencies
    local deps=$("$CROSSLDD" "$TARGET_DIR/$lib")
    for dep in $deps; do
         copy_library_with_symlinks "$TARGET_DIR/$dep"
    done
}

function add_executable {
    local bin="$1"
    cp "$TARGET_DIR/$bin" "bin/"
    # Find & copy library dependencies
    for dep in $("$CROSSLDD" "$TARGET_DIR/$bin"); do
        copy_library_with_symlinks "$TARGET_DIR/$dep"
    done
}

function add_module {
    local mod destmod deps
    # Search for the module
    mod=$(find "$TARGET_DIR"/lib/modules/$KERNELVERSION -type f -name "${1}.ko*")
    [ -z "$mod" ] && return 1
    # If it's already done, forget it
    destmod=${mod//$TARGET_DIR\//}
    [ -e "$destmod" ] && return 0
    # Install the module itself
    install -m 644 -D "$mod" "$destmod"
    # Install the firmwares it depends on
    for fw in $("$MODINFO" -F firmware $mod); do
        if [ -z "$fw" ]; then
            break
        elif [ -f "$TARGET_DIR/lib/firmware/$fw" ]; then
            install -m 644 -D "$TARGET_DIR/lib/firmware/$fw" "lib/firmware/$fw"
        else
            warn "Firmware $fw => not found"
        fi
    done
    # Install the other modules it depends on
    deps=$("$MODINFO" -F depends $mod)
    for m in ${deps//,/ }; do
        [ -n "$m" ] && add_module "$m"
    done
    return 0
}

function process_customs {
    logSubTitle "Creating directories"
    for dir in $DIRS
    do
       if [ ! -d "$dir" ]; then
          log "Creating $dir"
          mkdir -p "$dir"
       fi
    done
    logSubTitle "Installing libraries"
    for lib in $LIBS; do
        if [[ -f "$TARGET_DIR/$lib" ]]; then
            log "$lib"
            add_library "$lib"
        else
            err "$lib => not found"
        fi
    done
    logSubTitle "Installing executables"
    for bin in $BINS; do
        if [ -e "$TARGET_DIR/$bin" ]; then
            log "$bin"
            add_executable "$bin"
        else
            err "$bin => not found"
        fi
    done
    logSubTitle "Installing files and directories"
    for cpy in $COPY; do
        if [ -e "$TARGET_DIR/$cpy" ]; then
            log "$cpy"
            if [ -d "$TARGET_DIR/$cpy" ]; then
                d=$(dirname "$cpy")
                mkdir -p "$d"
            fi
            cp -ra "$TARGET_DIR/$cpy" "$cpy"
        else
            err "$cpy => not found"
        fi
    done
    logSubTitle "Installing kernel modules & firmwares"
    echo '#initramfs modules to load' > etc/modules
    for mod in $MODS; do
        if add_module $mod; then
            log "$mod"
            echo $mod >> etc/modules
        else
            err "$mod => not found"
        fi
    done
}

if [ $copyover -eq 1 ]; then
   logTitle "Reusing {BUILD_DIR}/initramfs directory ..."
else
   logTitle "Creating root into {BUILD_DIR}/initramfs ..."
   [ -d "$INITRAMFSDIR" ] && rm -rf "$INITRAMFSDIR"
fi

mkdir -p "$INITRAMFSDIR"
cd "$INITRAMFSDIR" || die "WTF ?!"

## DIRECTORY STRUCTURE ##
mkdir -p -m 0700 root
mkdir -p -m 0777 tmp run
mkdir -p -m 0755 dev sys proc etc var/{lock,run}
mkdir -p -m 0755 usr/{bin,sbin} usr/lib/firmware usr/lib/modules/$KERNELVERSION 
ln -sf usr/bin
ln -sf usr/sbin
ln -sf usr/lib
[ -L "$TARGET_DIR"/lib64 ] && { rm -f lib64; ln -s usr/lib lib64; }

## System files ##
cp -au "$TARGET_DIR"/etc/{passwd,group} etc/
ln -sf /proc/mounts etc/mtab

## Custom INIT Scripts ##
logSubTitle "Installing init scripts ..."
install -m 755    "$MAINDIR"/scripts/init              init
install -m 644 -D "$MAINDIR"/scripts/include/functions include/functions
install -m 644 -D "$MAINDIR"/scripts/include/log       include/log
ln -sf init linuxrc

## CONFIGURED CUSTOM OBJECTS ##
process_customs

logSubTitle "Resolving Kernel deps ..."
cp -a "$TARGET_DIR"/lib/modules/$KERNELVERSION/modules.{order,builtin} lib/modules/$KERNELVERSION/
"$HOST_DIR"/sbin/depmod -a -b "$INITRAMFSDIR" $KERNELVERSION

logSubTitle "Generating {BUILD_DIR}/initramfs.files ..."
find . | xargs ls -lhd > "$BUILD_DIR"/initramfs.files

logTitle "Generating initramfs into {OUTPUT}/images ..."

logSubTitle "Using $COMPRESSION & cpio ..."
shopt -s -o pipefail

find . | \
    "$HOST_DIR"/bin/fakeroot -- cpio -H newc -o --owner root:root | \
    $COMPRESSION -9 \
    > "$INITRAMFSFILE"

if [ $? -ne 0 ]; then
	err "${C_LRD}FAILED"
	status=1
else
	logTitle "${C_LGR}SUCCESS"
	status=0
fi

exit $status
