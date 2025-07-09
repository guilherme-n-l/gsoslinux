#!/bin/bash

colorize_stderr() {
    local RED='\033[31m'
    local RESET='\033[0m'
    while IFS= read -r line; do
        echo -e "${RED}${line}${RESET}" >&2
    done
}

[ $(whoami) != "lfs" ] && { echo "Must restore session first: \`sudo bash restore-session.sh\`" ; exit 1; }

su -c "
   umask 022
   mountpoint -q $LFS || mount -vm /dev/sda3 $LFS
   mountpoint -q $LFS/boot/efi || mount -vm /dev/sda1 $LFS/boot/efi
   swapon -s | grep -q "/dev/sda2" || swapon /dev/sda2

   chown -v root:root $LFS
   chmod -v 755 $LFS
   
   cd $LFS

   mkdir -v $LFS/sources
   chmod -v a+wt $LFS/sources
   tar xvf /home/lfs/lfs-packages-12.3.tar -C $LFS/sources --strip-components=1
   chown -v root:root $LFS/sources/*
   pushd $LFS/sources
   	md5sum -c md5sums
   popd

   mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
    
    for i in bin lib sbin; do
	ln -sv usr/\$i $LFS/\$i
    done
    
    case $(uname -m) in
        x86_64) mkdir -pv $LFS/lib64 ;;
    esac

    mkdir -pv $LFS/tools

    chown -v lfs $LFS/{usr{,/*},var,etc,tools}
    case $(uname -m) in
        x86_64) chown -v lfs $LFS/lib64 ;;
    esac

    pushd $LFS/sources
	find . -name '*.tar.*' -exec tar xvf {} \;
    popd

    chown -R lfs:lfs $LFS/sources
    chmod -R u+rw $LFS/sources
"
