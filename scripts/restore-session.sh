#!/bin/bash

[ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo bash $(basename $0)\`" ; exit 1; }

umask 022

LFS=/mnt/lfs
mountpoint -q $LFS || mount /dev/sda3 $LFS
mountpoint -q $LFS/boot/efi || mount /dev/sda1 $LFS/boot/efi
swapon --show=NAME | grep -q "^/dev/sda2$" || swapon /dev/sda2

su - lfs
