#!/bin/bash

[ $UID -eq 0 ] || exec sudo "$0" "$@"

cd $(dirname `readlink -f $0`)

. include/log || exit 1
. include/functions || exit 1

device=
update=0
image=sdcard.img
pv=$(which pv 2>/dev/null)

if [ "$1" = "-u" ]; then
	update=1
	shift
fi

[ -b "$1" ] || die "Usage: $0 [-u] block_device"

device=$1
[ -s $image ] || die "Cannot find '$image' !"

print_device_table $device
confirm

for mnt in $(grep $device /proc/mounts | cut -f1 -d' '); do
	log "Auto-unmounting $mnt ..."
	umount $mnt || die "Cannot unmount $mnt !"
done

if [ $update -eq 1 ]
then
	log "Updating existing partitions ..."
	lm=$(mktemp -d)
	dm=$(mktemp -d)
	ld=$(losetup --show -f -P "$image")
	mkdir -p "$lm" "$dm"
	for p in 1 2
	do
		log -- "- Syncing $image partition $p on $(ls ${device}*$p) ..."
		mount ${ld}p$p "$lm" || die "mount error !"
		mount ${device}*$p "$dm" || die "mount error !"
		rsync --inplace -a -u "$lm"/ "$dm"/ || die "rsync error !"
		umount "$lm" "$dm" || die "umount error !"
	done
	losetup -d "$ld"
	rmdir "$lm" "$dm"
else
	log "Flashing $image on $device ..."
	if [ -z "$pv" ]; then
		dd if="$image" of="$device" oflag=sync bs=4M status=progress
	else
		dd if="$image" bs=8M status=none \
		| $pv -w80 -s $(du -s -b sdcard.img | cut -f1) \
		| dd of="$device" oflag=sync bs=4M status=none
	fi
	sync
fi

log "Done!"

exit 0
