#!/bin/bash

LFS=/mnt/lfs

[[ ! -z "$(readlink /)" ]] && { echo "must run outside lfs chroot: \`exit\`" ; exit 1; }
[ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo bash $(basename $0)\`" ; exit 1; }

mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
mountpoint -q $LFS/dev/pts && umount $LFS/dev/pts
mountpoint -q $LFS/sys && umount $LFS/sys
mountpoint -q $LFS/proc && umount $LFS/proc
mountpoint -q $LFS/run && umount $LFS/run
mountpoint -q $LFS/dev && umount $LFS/dev

cd $LFS
tar -cJpf $HOME/lfs-12.3-systemd.tar.xz .
