#!/bin/bash

[ $UID -eq 0 ] || exec sudo "$0" "$@"

. include/log || exit 1
. include/functions || exit 1

device=

[ -b "$1" ] || die "Usage: $0 block_device"
device=$1
[ -s "sdcard.img" ] || die "Cannot find 'sdcard.img' !"

print_device_table $device
confirm

for mnt in $(grep $device /proc/mounts | cut -f1 -d' '); do
	log "Auto-unmounting $mnt ..."
	umount $mnt || die "Cannot unmount $mnt !"
done

dd if="sdcard.img" of="$device" oflag=sync bs=4M status=progress && sync

exit 0
