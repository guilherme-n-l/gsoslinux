#!/bin/bash

colorize_stderr() {
    local RED='\033[31m'
    local RESET='\033[0m'
    while IFS= read -r line; do
        echo -e "${RED}${line}${RESET}" >&2
    done
}

exec 2> >(colorize_stderr)

# Function to run a command and handle errors
run_command() {
    "$@" || { echo "Command failed: $@"; read; exit 1; }
}

[ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo bash $(basename $0)\`" ; exit 1; }

LFS=/mnt/lfs

run_command chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}

case $(uname -m) in
  x86_64) run_command chown --from lfs -R root:root $LFS/lib64 ;;
esac

run_command mkdir -pv $LFS/{dev,proc,sys,run}

mountpoint -q $LFS/dev || run_command mount -v --bind /dev $LFS/dev
mountpoint -q $LFS/dev/pts || run_command mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mountpoint -q $LFS/proc || run_command mount -vt proc proc $LFS/proc
mountpoint -q $LFS/sys || run_command mount -vt sysfs sysfs $LFS/sys
mountpoint -q $LFS/run || run_command mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  run_command install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mountpoint -q $LFS/dev/shm || run_command mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
