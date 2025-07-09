#!/bin/bash

[ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo bash $(basename $0)\`" ; exit 1; }

LFS=/mnt/lfs

if [ -d "$LFS" ]; then
	dev="$LFS/dev"
	[ -d "$dev" ] && mountpoint -q "$dev" && umount -v "$dev"
	find "$LFS" -maxdepth 1 -mindepth 1 ! -name "boot" -print -exec rm -rf {} +
	chown -v root:root $LFS
	chmod -v 755 $LFS
else
	echo "No $LFS dir. Maybe mount it..."
fi
