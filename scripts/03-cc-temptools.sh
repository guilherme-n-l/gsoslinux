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

# M4
cd $LFS/sources/m4-1.4.19

run_command ./configure --prefix=/usr   \
                        --host=$LFS_TGT \
                        --build=$(build-aux/config.guess)

run_command make
run_command make DESTDIR=$LFS install

# Ncurses
cd $LFS/sources/ncurses-6.5

mkdir build
pushd build
  run_command ../configure AWK=gawk
  run_command make -C include
  run_command make -C progs tic
popd

run_command ./configure --prefix=/usr                \
                        --host=$LFS_TGT              \
                        --build=$(./config.guess)    \
                        --mandir=/usr/share/man      \
                        --with-manpage-format=normal \
                        --with-shared                \
                        --without-normal             \
                        --with-cxx-shared            \
                        --without-debug              \
                        --without-ada                \
                        --disable-stripping          \
                        AWK=gawk

run_command make && run_command make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
run_command ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
run_command sed -e 's/^#if.*XOPEN.*$/#if 1/' -i $LFS/usr/include/curses.h

# Bash
cd $LFS/sources/bash-5.2.37

run_command ./configure --prefix=/usr   \
                        --build=$(sh support/config.guess)            \
                        --host=$LFS_TGT                               \
                        --without-bash-malloc

run_command sed -i 's/^CFLAGS_FOR_BUILD = -g -DCROSS_COMPILING$/CFLAGS_FOR_BUILD = -g -std=gnu17 -DCROSS_COMPILING/' builtins/Makefile

run_command make -j1 && run_command make DESTDIR=$LFS install
run_command ln -sv bash $LFS/bin/sh

# Coreutils
cd $LFS/sources/coreutils-9.6

run_command ./configure --prefix=/usr         \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

run_command make && run_command make DESTDIR=$LFS install

run_command mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
run_command mkdir -pv $LFS/usr/share/man/man8
run_command mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
run_command sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

# Diffutils
cd $LFS/sources/diffutils-3.11

run_command ./configure --prefix=/usr   \
            --host=$LFS_TGT             \
            --build=$(./build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# File
cd $LFS/sources/file-5.46

mkdir build
pushd build
  run_command ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  run_command make
popd

run_command ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
run_command make FILE_COMPILE=$(pwd)/build/src/file
run_command make DESTDIR=$LFS install
run_command rm -v $LFS/usr/lib/libmagic.la

# Findutils
cd $LFS/sources/findutils-4.10.0

run_command ./configure --prefix=/usr         \
            --localstatedir=/var/lib/locate   \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

run_command make && make DESTDIR=$LFS install

Gawk
cd $LFS/sources/gawk-5.3.1

run_command sed -i 's/extras//' Makefile.in

run_command ./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Grep
cd $LFS/sources/grep-3.11

run_command ./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Gzip
cd $LFS/sources/gzip-1.13

run_command ./configure --prefix=/usr --host=$LFS_TGT
run_command make && run_command make DESTDIR=$LFS install

# Make
cd $LFS/sources/make-4.4.1

run_command ./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Patch
cd $LFS/sources/patch-2.7.6

run_command ./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Sed
cd $LFS/sources/sed-4.9

run_command ./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Tar
cd $LFS/sources/tar-1.35

run_command ./configure --prefix=/usr         \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

run_command make && run_command make DESTDIR=$LFS install

# Xz
cd $LFS/sources/xz-5.6.4

run_command ./configure --prefix=/usr         \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.4

run_command make && run_command make DESTDIR=$LFS install

run_command rm -v $LFS/usr/lib/liblzma.la

# Binutils - pass 2
rm -rf $LFS/sources/binutils-2.44
cd $LFS/sources && tar xvf binutils-2.44.tar.xz
cd $LFS/sources/binutils-2.44
run_command sed '6031s/$add_dir//' -i ltmain.sh

mkdir build
cd build
run_command ../configure       \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu

run_command make && run_command make DESTDIR=$LFS install
run_command rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

# GCC - pass 2
rm -rf $LFS/sources/gcc-14.2.0
cd $LFS/sources && tar xvf gcc-14.2.0.tar.xz
cd $LFS/sources/gcc-14.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    run_command sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

run_command sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir build
cd build
run_command ../configure                           \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++

run_command make && run_command make DESTDIR=$LFS install
run_command ln -sv gcc $LFS/usr/bin/cc

