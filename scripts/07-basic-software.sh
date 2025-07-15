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

[[ "$(readlink /)" == "/" ]] && { echo "must run inside lfs chroot: \`sudo bash 05-chroot.sh\`" ; exit 1; }

# Man-pages
cd /sources/man-pages-6.12

rm -v man3/crypt*

run_command make -R GIT=false prefix=/usr install

# Iana-Etc
cd /sources/iana-etc-20250123

run_command cp services protocols /etc

# Glibc
rm -rf /sources/glibc-2.41
cd /sources
tar xvf /sources/glibc-2.41.tar.xz
cd /sources/glibc-2.41

run_command patch -Np1 -i ../glibc-2.41-fhs-1.patch

mkdir -v build
cd build

echo "rootsbindir=/usr/sbin" > configparms



run_command ../configure --prefix=/usr                		  \
             		 --disable-werror                         \
             		 --enable-kernel=5.4                      \
             		 --enable-stack-protector=strong          \
             		 --disable-nscd                           \
             libc_cv_slibdir=/usr/lib

run_command make
make check

run_command touch /etc/ld.so.conf

run_command sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

run_command make install

run_command sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

run_command localedef -i C -f UTF-8 C.UTF-8
run_command localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
run_command localedef -i de_DE -f ISO-8859-1 de_DE
run_command localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
run_command localedef -i de_DE -f UTF-8 de_DE.UTF-8
run_command localedef -i el_GR -f ISO-8859-7 el_GR
run_command localedef -i en_GB -f ISO-8859-1 en_GB
run_command localedef -i en_GB -f UTF-8 en_GB.UTF-8
run_command localedef -i en_HK -f ISO-8859-1 en_HK
run_command localedef -i en_PH -f ISO-8859-1 en_PH
run_command localedef -i en_US -f ISO-8859-1 en_US
run_command localedef -i en_US -f UTF-8 en_US.UTF-8
run_command localedef -i es_ES -f ISO-8859-15 es_ES@euro
run_command localedef -i es_MX -f ISO-8859-1 es_MX
run_command localedef -i fa_IR -f UTF-8 fa_IR
run_command localedef -i fr_FR -f ISO-8859-1 fr_FR
run_command localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
run_command localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
run_command localedef -i is_IS -f ISO-8859-1 is_IS
run_command localedef -i is_IS -f UTF-8 is_IS.UTF-8
run_command localedef -i it_IT -f ISO-8859-1 it_IT
run_command localedef -i it_IT -f ISO-8859-15 it_IT@euro
run_command localedef -i it_IT -f UTF-8 it_IT.UTF-8
run_command localedef -i ja_JP -f EUC-JP ja_JP
run_command localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
run_command localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
run_command localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
run_command localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
run_command localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
run_command localedef -i se_NO -f UTF-8 se_NO.UTF-8
run_command localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
run_command localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
run_command localedef -i zh_CN -f GB18030 zh_CN.GB18030
run_command localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
run_command localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
run_command localedef -i pt_BR -f ISO-8859-1 pt_BR
run_command localedef -i pt_BR -f UTF-8 pt_BR.UTF-8

run_command cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

run_command rm -rf ../../tzdata2025a.tar.gz
tar -xf ../../tzdata2025a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    run_command zic -L /dev/null   -d $ZONEINFO       ${tz}
    run_command zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    run_command zic -L leapseconds -d $ZONEINFO/right ${tz}
done

run_command cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
run_command zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

TZ='America/Sao_Paulo'
run_command ln -sfv /usr/share/zoneinfo/$TZ /etc/localtime
unset TZ

run_command cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

# Zlib
cd /sources/zlib-1.3.1

run_command ./configure --prefix=/usr
run_command make
run_command make check
run_command make install

run_command rm -fv /usr/lib/libz.a

# Bzip
cd /sources/bzip2-1.0.8

run_command patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

run_command sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

run_command sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

run_command make -f Makefile-libbz2_so
run_command make clean
run_command make
run_command make PREFIX=/usr install
run_command cp -av libbz2.so.* /usr/lib
run_command ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
run_command cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  run_command ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

# Xz
rm /sources/xz-5.6.4
cd /sources
tar xvf xz-5.6.4.tar.xz
cd /sources/xz-5.6.4

run_command ./configure --prefix=/usr    	\
            		--disable-static 	\
            		--docdir=/usr/share/doc/xz-5.6.4

run_command make
run_command make check
run_command make install

# Lz4
cd /sources/lz4-1.10.0

run_command make BUILD_STATIC=no PREFIX=/usr
run_command make -j1 check
run_command make BUILD_STATIC=no PREFIX=/usr install

# Zstd
cd /sources/zstd-1.5.7

run_command make prefix=/usr
run_command make check
run_command make prefix=/usr install

rm -v /usr/lib/libzstd.a

# File
rm /sources/file-5.46
cd /sources
tar xvf file-5.46.tar.gz
cd /sources/file-5.46

./configure --prefix=/usr

make
make check
make install

# Readline
cd /sources/readline-8.2.13

run_command sed -i '/MV.*old/d' Makefile.in
run_command sed -i '/{OLDSUFF}/c:' support/shlib-install
run_command sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

run_command ./configure --prefix=/usr    \
			--disable-static \
            		--with-curses    \
            		--docdir=/usr/share/doc/readline-8.2.13

run_command make SHLIB_LIBS="-lncursesw"
run_command make install
run_command install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13

# M4
rm /sources/m4-1.4.19
cd /sources
tar xvf m4-1.4.19.tar.xz
cd /sources/m4-1.4.19

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Bc
cd /sources/bc-7.0.3

CC=gcc run_command ./configure --prefix=/usr -G -O3 -r

run_command make 
run_command make test
run_command make install

# Flex
cd /sources/flex-2.6.4

run_command ./configure --prefix=/usr \
            		--docdir=/usr/share/doc/flex-2.6.4 \
            		--disable-static

run_command make 
run_command make check
run_command make install

run_command ln -sv flex   /usr/bin/lex
run_command ln -sv flex.1 /usr/share/man/man1/lex.1

# Tcl
cd /sources/tcl8.6.16

srcdir=$(pwd)
cd unix
run_command ./configure --prefix=/usr           \
            		--mandir=/usr/share/man \
            		--disable-rpath

run_command make

run_command sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

run_command sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"            \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

run_command sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh

unset SRCDIR

run_command make test
run_command make install
run_command chmod -v u+w /usr/lib/libtcl8.6.so
run_command make install-private-headers
run_command ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
tar -xf ../tcl8.6.16-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.16
run_command cp -v -r  ./html/* /usr/share/doc/tcl-8.6.16

# Expect
cd /sources/expect5.45.4

python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
echo -n "OK?: "
read

run_command patch -Np1 -i ../expect-5.45.4-gcc14-1.patch
run_command ./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

run_command make
run_command make test
run_command make install
run_command ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

# DejaGNU
cd /sources/dejagnu-1.6.3

mkdir -v build
cd build

run_command ../configure --prefix=/usr
run_command makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
run_command makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

run_command make check
run_command make install
run_command install -v -dm755  /usr/share/doc/dejagnu-1.6.3
run_command install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

# Pkgconf
cd /sources/pkgconf-2.3.0

run_command ./configure --prefix=/usr              \
            		--disable-static           \
            		--docdir=/usr/share/doc/pkgconf-2.3.0

run_command make
run_command make install

run_command ln -sv pkgconf /usr/bin/pkg-config
run_command ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

# Binutils
rm -rf /sources/binutils-2.44
cd /sources
tar xvf /sources/binutils-2.44.tar.xz
cd /sources/binutils-2.44

mkdir -v build
cd build

run_command ../configure --prefix=/usr       \
             		 --sysconfdir=/etc   \
             		 --enable-ld=default \
             		 --enable-plugins    \
             		 --enable-shared     \
             		 --disable-werror    \
             		 --enable-64-bit-bfd \
             		 --enable-new-dtags  \
             		 --with-system-zlib  \
             		 --enable-default-hash-style=gnu
run_command make tooldir=/usr
run_command make -k check
echo "Printing fails:"
grep '^FAIL:' $(find -name '*.log')
echo -n "Ok?: "
read

run_command make tooldir=/usr install

rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/

# GMP
cd /sources/gmp-6.3.0

run_command ./configure --prefix=/usr    \
            		--enable-cxx     \
            		--disable-static \
            		--docdir=/usr/share/doc/gmp-6.3.0

run_command make
run_command make html
run_command make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
echo -n "Ok? (>= 199): "
read

run_command make install

# MPC
cd /sources/mpc-1.3.1

run_command ./configure --prefix=/usr        \
            		--disable-static     \
            		--enable-thread-safe \
            		--docdir=/usr/share/doc/mpfr-4.2.1
run_command make
run_command make html
run_command make check 2>&1 | tee mpfr-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' mpfr-check-log
echo -n "Ok? (>= 198): "
read

run_command make install
run_command make install-html

# MPC
cd /sources/mpc-1.3.1

run_command ./configure --prefix=/usr    \
            		--disable-static \
            		--docdir=/usr/share/doc/mpc-1.3.1

run_command make
run_command make html
run_command make check
run_command make install
run_command make install-html

# Attr
cd /sources/attr-2.5.2

run_command ./configure --prefix=/usr     \
            		--disable-static  \
            		--sysconfdir=/etc \
            		--docdir=/usr/share/doc/attr-2.5.2

run_command make
run_command make check
run_command make install

# Acl
cd /sources/acl-2.3.2

run_command ./configure --prefix=/usr         \
            		--disable-static      \
            		--docdir=/usr/share/doc/acl-2.3.2

run_command make
make check
run_command make install

# Libcap
cd /sources/libcap-2.73

run_command sed -i '/install -m.*STA/d' libcap/Makefile
run_command make prefix=/usr lib=lib
run_command make test
run_command make prefix=/usr lib=lib install

# Libxcrypt
cd /sources/libxcrypt-4.4.38

run_command ./configure --prefix=/usr                \
            		--enable-hashes=strong,glibc \
            		--enable-obsolete-api=no     \
            		--disable-static             \
            		--disable-failure-tokens

run_command make
run_command make check
run_command make install

# Shadow
cd /sources/shadow-4.17.3

run_command sed -i 's/groups$(EXEEXT) //' src/Makefile.in
run_command find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
run_command find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
run_command find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;--enable-obsolete-api=no     \
run_command sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    		-e 's:/var/spool/mail:/var/mail:'                   \
    		-e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    		-i etc/login.defs
            		--disable-static             \
            		--disable-failure-tokens
touch /usr/bin/passwd
run_command ./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

run_command make
run_command make exec_prefix=/usr install
run_command make -C man install-man

run_command pwconv
run_command grpconv
run_command mkdir -p /etc/default
run_command useradd -D --gid 999

echo "Please enter new password for root"
passwd root

# GCC
rm -rf /sources/gcc-14.2.0
cd /sources
tar xvf /sources/gcc-14.2.0.tar.xz
cd gcc-14.2.0

case $(uname -m) in
  x86_64)
    run_command sed -e '/m64=/s/lib64/lib/' \
        	    -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir -v build
cd build

run_command ../configure --prefix=/usr            \
             		 LD=ld                    \
             		 --enable-languages=c,c++ \
             		 --enable-default-pie     \
             		 --enable-default-ssp     \
             		 --enable-host-pie        \
             		 --disable-multilib       \
             		 --disable-bootstrap      \
             		 --disable-fixincludes    \
             		 --with-system-zlib

run_command make
run_command ulimit -s -H unlimited

run_command sed -e '/cpython/d'               -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
run_command sed -e 's/no-pic /&-no-pie /'     -i ../gcc/testsuite/gcc.target/i386/pr113689-1.c
run_command sed -e 's/300000/(1|300000)/'     -i ../libgomp/testsuite/libgomp.c-c++-common/pr109062.c
run_command sed -e 's/{ target nonpic } //' \
    		-e '/GOTPCREL/d'              -i ../gcc/testsuite/gcc.target/i386/fentryname3.c

chown -R tester .
run_command su tester -c "PATH=$PATH make -j$(nproc) -k check"
run_command make install
run_command chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}

run_command ln -svr /usr/bin/cpp /usr/lib
run_command ln -sv gcc.1 /usr/share/man/man1/cc.1
run_command ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
echo -n "OK? ([Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]): "
read

grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
echo -n "OK? (3 lines with succeeded): "
read

grep -B4 '^ /usr/include' dummy.log
echo -n "OK? (if x86_64: .../x86_64-pc-linux-gnu/.../include | /usr/local/include | .../x86_64-pc-linux-gnu/.../include-fixed | /usr/include): "
read

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
echo -n "OK? (if x86_64: contains lib64 x86_64-pc-linux-gnu and lib): "
read

grep "/lib.*/libc.so.6 " dummy.log
echo -n "OK? (1 line with succeeded): "
read

grep found dummy.log
echo -n "OK? (1 line with found): "
read

rm -v dummy.c a.out dummy.log

run_command mkdir -pv /usr/share/gdb/auto-load/usr/lib
run_command mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

# Ncurses
rm -rf /sources/ncurses-6.5
cd /sources
tar xvf /sources/ncurses-6.5.tar.gz
cd /sources/ncurses-6.5

run_command ./configure --prefix=/usr           \
	                --mandir=/usr/share/man \
	                --with-shared           \
	                --without-debug         \
	                --without-normal        \
	                --with-cxx-shared       \
	                --enable-pc-files       \
	                --with-pkg-config-libdir=/usr/lib/pkgconfig
run_command make

run_command make DESTDIR=$PWD/dest install
run_command install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
run_command rm -v  dest/usr/lib/libncursesw.so.6.5
run_command sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    		-i dest/usr/include/curses.h
run_command cp -av dest/* /

for lib in ncurses form panel menu ; do
    run_command ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    run_command ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

run_command ln -sfv libncursesw.so /usr/lib/libcurses.so

run_command cp -v -R doc -T /usr/share/doc/ncurses-6.5

# Ncurses
rm -rf /sources/sed-4.9
cd /sources
tar xvf /sources/sed-4.9.tar.xz
cd /sources/sed-4.9

run_command ./configure --prefix=/usr

run_command make
run_command make html

chown -R tester .
run_command su tester -c "PATH=$PATH make check"

run_command make install
run_command install -d -m755 usr/share/doc/sed-4.9
run_command install -m644 doc/sed.html /usr/share/doc/sed-4.9

# Psmisc
cd /sources/psmisc-23.7

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Gettext
rm -rf /sources/gettext-0.24
cd /sources
tar xvf /sources/gettext-0.24.tar.xz
cd /sources/gettext-0.24

run_command make
run_command make check
run_command make install

run_command chmod -v 0755 /usr/lib/preloadable_libintl.so

# Bison
rm -rf /sources/bison-3.8.2
cd /sources
tar xvf /sources/bison-3.8.2.tar.xz
cd /sources/bison-3.8.2

run_command ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

run_command make
run_command make check
run_command make install

# Grep
rm -rf /sources/grep-3.11
cd /sources
tar xvf /sources/grep-3.11.tar.xz
cd /sources/grep-3.11

run_command sed -i "s/echo/#echo/" src/egrep.sh
run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Bash
rm -rf /sources/bash-5.2.37
cd /sources
tar xvf /sources/bash-5.2.37.tar.gz
cd /sources/bash-5.2.37

run_command ./configure --prefix=/usr             \
	                --without-bash-malloc     \
	                --with-installed-readline \
	                --docdir=/usr/share/doc/bash-5.2.37

run_command make

chown -R tester .

run_command su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

run_command make install

# Libtool
cd /sources/libtool-2.5.4

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

rm -fv /usr/lib/libltdl.a

# GDBM
cd /sources/gdbm-1.24

run_command ./configure --prefix=/usr    \
            		--disable-static \
            		--enable-libgdbm-compat

run_command make
run_command make check
run_command make install

# Gperf
cd /sources/gperf-3.1

run_command ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
run_command make
run_command make -j1 check
run_command make install

# Expat
cd /sources/expat-2.6.4

run_command ./configure --prefix=/usr    \
            		--disable-static \
            		--docdir=/usr/share/doc/expat-2.6.4
run_command make
run_command make check
run_command make install

run_command install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.4

# Inetutils
cd /sources/inetutils-2.6

run_command sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
run_command ./configure --prefix=/usr        \
            		--bindir=/usr/bin    \
            		--localstatedir=/var \
            		--disable-logger     \
            		--disable-whois      \
            		--disable-rcp        \
            		--disable-rexec      \
            		--disable-rlogin     \
            		--disable-rsh        \
            		--disable-servers

run_command make
run_command make check
run_command make install

run_command mv -v /usr/{,s}bin/ifconfig

# Less
cd /sources/less-668

run_command ./configure --prefix=/usr --sysconfdir=/etc

run_command make
run_command make check
run_command make install

# Perl
rm -rf /sources/perl-5.40.1
cd /sources
tar xvf /sources/perl-5.40.1.tar.xz
cd /sources/perl-5.40.1

export BUILD_ZLIB=False
export BUILD_BZIP2=0

run_command sh Configure -des                                          \
             		 -D prefix=/usr                                \
             		 -D vendorprefix=/usr                          \
             		 -D privlib=/usr/lib/perl5/5.40/core_perl      \
             		 -D archlib=/usr/lib/perl5/5.40/core_perl      \
             		 -D sitelib=/usr/lib/perl5/5.40/site_perl      \
             		 -D sitearch=/usr/lib/perl5/5.40/site_perl     \
             		 -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
             		 -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             		 -D man1dir=/usr/share/man/man1                \
             		 -D man3dir=/usr/share/man/man3                \
             		 -D pager="/usr/bin/less -isR"                 \
             		 -D useshrplib                                 \
             		 -D usethreads

run_command make
run_command TEST_JOBS=$(nproc) make test_harness
run_command make install
unset BUILD_ZLIB BUILD_BZIP2

# XML::Parser (Perl)
cd /sources/XML-Parser-2.47

run_command perl Makefile.PL

run_command make
run_command make test
run_command make install

# Intltool
cd /sources/intltool-0.51.0

run_command sed -i 's:\\\${:\\\$\\{:' intltool-update.in

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install
run_command install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

# Autoconf
cd /sources/autoconf-2.72

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Automake
cd /sources/automake-1.17

run_command ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17

run_command make
run_command make -j$(($(nproc)>4?$(nproc):4)) check
run_command make install

# OpenSSL
cd /sources/openssl-3.4.1

run_command ./config --prefix=/usr         \
         	     --openssldir=/etc/ssl \
         	     --libdir=lib          \
         	     shared                \
         	     zlib-dynamic

run_command make
run_command HARNESS_JOBS=$(nproc) make test

run_command sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
run_command make MANSUFFIX=ssl install

run_command mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.4.1

run_command cp -vfr doc/* /usr/share/doc/openssl-3.4.1

# Libelf
cd /sources/elfutils-0.192

run_command ./configure --prefix=/usr                \
            		--disable-debuginfod         \
            		--enable-libdebuginfod=dummy

run_command make
run_command make check

run_command make -C libelf install
run_command install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

# Libffi
cd /sources/libffi-3.4.7

run_command ./configure --prefix=/usr          \
            		--disable-static       \
            		--with-gcc-arch=native

run_command make
run_command make check
run_command make install

# Python
rm -rf /sources/Python-3.13.2
cd /sources
tar xvf Python-3.13.2.tar.xz
cd /sources/Python-3.13.2

run_command ./configure --prefix=/usr        \
            		--enable-shared      \
            		--with-system-expat  \
            		--enable-optimizations

run_command make
run_command make test TESTOPTS="--timeout 120"
run_command make install

run_command install -v -dm755 /usr/share/doc/python-3.13.2/html
run_command tar --strip-components=1  \
    		--no-same-owner       \
    		--no-same-permissions \
    		-C /usr/share/doc/python-3.13.2/html \
    		-xvf ../python-3.13.2-docs-html.tar.bz2

# Flit-Core (Python)
cd /sources/flit_core-3.11.0

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
run_command pip3 install --no-index --find-links dist flit_core

# Wheel (Python)
cd /sources/wheel-0.45.1

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
run_command pip3 install --no-index --find-links dist wheel

# Setuptools (Python)
cd /sources/setuptools-75.8.1

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
run_command pip3 install --no-index --find-links dist setuptools

# Ninja (Python)
cd /sources/ninja-1.12.1

export NINJAJOBS=4
run_command sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

run_command python3 configure.py --bootstrap --verbose
run_command install -vm755 ninja /usr/bin/
run_command install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
run_command install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
unset NINJAJOBS

# Meson (Python)
cd /sources/meson-1.7.0

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

run_command pip3 install --no-index --find-links dist meson
run_command install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
run_command install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

# Kmod
cd /sources/kmod-34

mkdir -p build
cd build

run_command meson setup --prefix=/usr ..    \
            		--sbindir=/usr/sbin \
            		--buildtype=release \
            		-D manpages=false

run_command ninja
run_command ninja install

# Coreutils
rm -rf /sources/coreutils-9.6
cd /sources
tar xvf /sources/coreutils-9.6.tar.xz
cd /sources/coreutils-9.6

run_command patch -Np1 -i ../coreutils-9.6-i18n-1.patch

run_command autoreconf -fv
run_command automake -af
run_command FORCE_UNSAFE_CONFIGURE=1 ./configure \
            		--prefix=/usr            \
            		--enable-no-install-program=kill,uptime

run_command make
run_command make NON_ROOT_USERNAME=tester check-root

run_command groupadd -g 102 dummy -U tester

chown -R tester .
run_command su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   		< /dev/null

run_command groupdel dummy

run_command make install

run_command mv -v /usr/bin/chroot /usr/sbin
run_command mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
run_command sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

# Check
cd /sources/check-0.15.2

run_command ./configure --prefix=/usr --disable-static

run_command make
run_command make check
run_command make docdir=/usr/share/doc/check-0.15.2 install

# Diffutils
rm -rf /sources/diffutils-3.11
cd /sources
tar xvf /sources/diffutils-3.11.tar.xz
cd /sources/diffutils-3.11

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Gawk
rm -rf /sources/gawk-5.3.1
cd /sources
tar xvf /sources/gawk-5.3.1.tar.xz
cd /sources/gawk-5.3.1

run_command sed -i 's/extras//' Makefile.in

run_command ./configure --prefix=/usr

run_command make

chown -R tester .
run_command su tester -c "PATH=$PATH make check"

rm -f /usr/bin/gawk-5.3.1
run_command make install

run_command ln -sv gawk.1 /usr/share/man/man1/awk.1
run_command install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.1

# Findutils
rm -rf /sources/findutils-4.10.0
cd /sources
tar xvf /sources/findutils-4.10.0.tar.xz
cd /sources/findutils-4.10.0

run_command ./configure --prefix=/usr --localstatedir=/var/lib/locate

run_command make

chown -R tester .
run_command su tester -c "PATH=$PATH make check"
run_command make install

# Groff
cd /sources/groff-1.23.0

PAPER_SIZE=A4
PAGE=$PAPER_SIZE ./configure --prefix=/usr
unset PAPER_SIZE

run_command make
run_command make check
run_command make install

# Grub (UEFI - BLFS)
cd /sources/grub-2.12

unset {C,CPP,CXX,LD}FLAGS
run_command echo depends bli part_gpt > grub-core/extra_deps.lst

run_command ./configure --prefix=/usr        \
            		--sysconfdir=/etc    \
            		--disable-efiemu     \
            		--with-platform=efi  \
            		--target=x86_64      \
            		--disable-werror

run_command make
run_command make install

run_command mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

# Gzip
rm -rf /sources/gzip-1.13
cd /sources
tar xvf /sources/gzip-1.13.tar.xz
cd /sources/gzip-1.13

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# IPRoute2
cd /sources/iproute2-6.13.0

run_command sed -i /ARPD/d Makefile
run_command rm -fv man/man8/arpd.8

run_command make NETNS_RUN_DIR=/run/netns
run_command make SBINDIR=/usr/sbin install
run_command install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.13.0

# Kbd
cd /sources/kbd-2.7.1

run_command patch -Np1 -i ../kbd-2.7.1-backspace-1.patch

run_command sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
run_command sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

run_command ./configure --prefix=/usr --disable-vlock

run_command make
run_command make check
run_command make install

run_command cp -R -v docs/doc -T /usr/share/doc/kbd-2.7.1

# Libpipeline
cd /sources/libpipeline-1.5.8

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Make
rm -rf /sources/make-4.4.1
cd /sources
tar xvf /sources/make-4.4.1.tar.gz
cd /sources/make-4.4.1

run_command ./configure --prefix=/usr

run_command make
chown -R tester .
run_command su tester -c "PATH=$PATH make check"

run_command make install

# Patch
rm -rf /sources/patch-2.7.6
cd /sources
tar xvf /sources/patch-2.7.6.tar.xz
cd /sources/patch-2.7.6

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

# Tar
rm -rf /sources/tar-1.35
cd /sources
tar xvf /sources/tar-1.35.tar.xz
cd /sources/tar-1.35

run_command FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

run_command make -C doc install-html docdir=/usr/share/doc/tar-1.35

# Texinfo
rm -rf /sources/texinfo-7.2
cd /sources
tar xvf /sources/texinfo-7.2.tar.xz
cd /sources/texinfo-7.2

run_command ./configure --prefix=/usr

run_command make
run_command make check
run_command make install

run_command make TEXMF=/usr/share/texmf install-tex

# Vim (BTW)
cd /sources/vim-9.1.1166

run_command echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
run_command ./configure --prefix=/usr

run_command make

run_command chown -R tester .
run_command sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak
run_command su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" &> vim-test.log

tail vim-test.log
echo -n "Ok? (0 failed): "
read

run_command make install

run_command ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    run_command ln -sv vim.1 $(dirname $L)/vi.1
done

run_command ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1166

# MarkupSafe (Python)
cd /sources/markupsafe-3.0.2

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
run_command pip3 install --no-index --find-links dist Markupsafe

# Jinja 2 (Python)
cd /sources/jinja2-3.1.5

run_command pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
run_command pip3 install --no-index --find-links dist Jinja2

# Systemd
cd /sources/systemd-257.3

run_command sed -e 's/GROUP="render"/GROUP="video"/' \
    		-e 's/GROUP="sgx", //'               \
    		-i rules.d/50-udev-default.rules.in

mkdir -p build
cd build

run_command meson setup ..                \
      		  --prefix=/usr           \
      		  --buildtype=release     \
      		  -D default-dnssec=no    \
      		  -D firstboot=false      \
      		  -D install-tests=false  \
      		  -D ldconfig=false       \
      		  -D sysusers=false       \
      		  -D rpmmacrosdir=no      \
      		  -D homed=disabled       \
      		  -D userdb=false         \
      		  -D man=disabled         \
      		  -D mode=release         \
      		  -D pamconfdir=no        \
      		  -D dev-kvm-mode=0660    \
      		  -D nobody-group=nogroup \
      		  -D sysupdate=disabled   \
      		  -D ukify=disabled       \
      		  -D docdir=/usr/share/doc/systemd-257.3

run_command ninja
run_command echo 'NAME="Guilhermes Shitty Operating System"' > /etc/os-release
run_command ninja test
run_command ninja install

run_command tar -xf ../../systemd-man-pages-257.3.tar.xz \
    		--no-same-owner --strip-components=1     \
    		-C /usr/share/man

systemd-machine-id-setup
systemctl preset-all

# D-Bus
cd /sources/dbus-1.16.0

mkdir -p build
cd build

run_command meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..

run_command ninja
run_command ninja test
run_command ninja install

run_command ln -sfv /etc/machine-id /var/lib/dbus

# Man-DB
cd /sources/man-db-2.13.0

run_command ./configure --prefix=/usr                         \
            		--docdir=/usr/share/doc/man-db-2.13.0 \
            		--sysconfdir=/etc                     \
            		--disable-setuid                      \
            		--enable-cache-owner=bin              \
            		--with-browser=/usr/bin/lynx          \
            		--with-vgrind=/usr/bin/vgrind         \
            		--with-grap=/usr/bin/grap

run_command make
run_command make check
run_command make install

# Procps-ng
cd /sources/procps-ng-4.0.5

run_command ./configure --prefix=/usr                           \
            		--docdir=/usr/share/doc/procps-ng-4.0.5 \
            		--disable-static                        \
            		--disable-kill                          \
            		--enable-watch8bit                      \
            		--with-systemd

run_command make

chown -R tester .
run_command su tester -c "PATH=$PATH make check"
run_command make install

# Util-Linux
rm -rf /sources/util-linux-2.40.4
cd /sources
tar xvf /sources/util-linux-2.40.4.tar.xz
cd /sources/util-linux-2.40.4

run_command ./configure --bindir=/usr/bin     \
            		--libdir=/usr/lib     \
            		--runstatedir=/run    \
            		--sbindir=/usr/sbin   \
            		--disable-chfn-chsh   \
            		--disable-login       \
            		--disable-nologin     \
            		--disable-su          \
            		--disable-setpriv     \
            		--disable-runuser     \
            		--disable-pylibmount  \
            		--disable-liblastlog2 \
            		--disable-static      \
            		--without-python      \
            		ADJTIME_PATH=/var/lib/hwclock/adjtime \
            		--docdir=/usr/share/doc/util-linux-2.40.4

run_command make

touch /etc/fstab
chown -R tester .
run_command su tester -c "make -k check"
 
run_command make install

# E2fsprogs
cd /sources/e2fsprogs-1.47.2

mkdir -v build
cd build

run_command ../configure --prefix=/usr           \
             		 --sysconfdir=/etc       \
             		 --enable-elf-shlibs     \
             		 --disable-libblkid      \
             		 --disable-libuuid       \
             		 --disable-uuidd         \
             		 --disable-fsck

run_command make
run_command make check
run_command make install

rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

run_command gunzip -v /usr/share/info/libext2fs.info.gz
run_command install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

run_command makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
run_command install -v -m644 doc/com_err.info /usr/share/info
run_command install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
