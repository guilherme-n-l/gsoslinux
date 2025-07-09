#!/bin/bash

colorize_stderr() {
    local RED='\033[31m'
    local RESET='\033[0m'
    while IFS= read -r line; do
        echo -e "${RED}${line}${RESET}" >&2
    done
}

su -c "
    mkdir -v $LFS/sources
    chmod -v a+wt $LFS/sources
    cp /home/lfs/lfs-packages-12.3.tar $LFS/sources
    chown root:root $LFS/sources/*

    mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
    
    for i in bin lib sbin; do
        ln -sv $LFS/usr/$i $LFS/$i
    done
    
    case $(uname -m) in
        x86_64) mkdir -pv $LFS/lib64 ;;
    esac

    mkdir -pv $LFS/tools
    chown -v lfs $LFS/{usr{,/*},var,etc,tools}
    case $(uname -m) in
        x86_64) chown -v lfs $LFS/lib64 ;;
    esac
"

cd $LFS/sources
tar xvf $LFS/sources/lfs-packages-12.3.tar
mv 12.3/* . && rm -rf 12.3/
rm -rf lfs-packages-12.3.tar

pushd $LFS/sources
    md5sum -c md5sums
    find . -name "*.tar.*" -exec tar xvf {} \;
popd
