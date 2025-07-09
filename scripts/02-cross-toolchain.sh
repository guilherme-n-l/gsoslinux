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

# Binutils
cd $LFS/sources/binutils-2.44
mkdir -v build
cd build
run_command ../configure --prefix=$LFS/tools \
                          --with-sysroot=$LFS \
                          --target=$LFS_TGT   \
                          --disable-nls       \
                          --enable-gprofng=no \
                          --disable-werror    \
                          --enable-new-dtags  \
                          --enable-default-hash-style=gnu

run_command make
run_command make install

# GCC
cd $LFS/sources/gcc-14.2.0

run_command tar -xf ../mpfr-4.2.1.tar.xz
run_command mv -v mpfr-4.2.1 mpfr
run_command tar -xf ../gmp-6.3.0.tar.xz
run_command mv -v gmp-6.3.0 gmp
run_command tar -xf ../mpc-1.3.1.tar.gz
run_command mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    run_command sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build
cd build
run_command ../configure --target=$LFS_TGT         \
                         --prefix=$LFS/tools       \
                         --with-glibc-version=2.41 \
                         --with-sysroot=$LFS       \
                         --with-newlib             \
                         --without-headers         \
                         --enable-default-pie      \
                         --enable-default-ssp      \
                         --disable-nls             \
                         --disable-shared          \
                         --disable-multilib        \
                         --disable-threads         \
                         --disable-libatomic       \
                         --disable-libgomp         \
                         --disable-libquadmath     \
                         --disable-libssp          \
                         --disable-libvtv          \
                         --disable-libstdcxx       \
                         --enable-languages=c,c++

run_command make
run_command make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

# Linux headers
cd $LFS/sources/linux-6.13.4

run_command make mrproper
run_command make headers
find usr/include -type f ! -name '*.h' -delete
run_command cp -rv usr/include $LFS/usr

# Glibc
cd $LFS/sources/glibc-2.41

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3 ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3 ;;
esac

run_command patch -Np1 -i ../glibc-2.41-fhs-1.patch

mkdir -v build
cd build

echo "rootsbindir=/usr/sbin" > configparms

run_command ../configure --prefix=/usr                      \
                          --host=$LFS_TGT                    \
                          --build=$(../scripts/config.guess) \
                          --enable-kernel=5.4                \
                          --with-headers=$LFS/usr/include    \
                          --disable-nscd                     \
                          libc_cv_slibdir=/usr/lib

run_command make
run_command make DESTDIR=$LFS install

run_command sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
run_command readelf -l a.out | grep ld-linux

read

run_command rm -v a.out

# Libstdc++
cd $LFS/sources
run_command rm -rf gcc-14.2.0
run_command tar xvf gcc-14.2.0.tar.xz
cd gcc-14.2.0

mkdir -v build
cd build

run_command ../libstdc++-v3/configure --host=$LFS_TGT                 \
                                      --build=$(../config.guess)      \
                                      --prefix=/usr                   \
                                      --disable-multilib              \
                                      --disable-nls                   \
                                      --disable-libstdcxx-pch         \
                                      --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0

run_command make
run_command make DESTDIR=$LFS install

run_command rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
