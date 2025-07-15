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

mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

run_command ln -sfv /run /var/run
run_command ln -sfv /run/lock /var/lock

run_command install -dv -m 0750 /root
run_command install -dv -m 1777 /tmp /var/tmp

run_command ln -sv /proc/self/mounts /etc/mtab

run_command cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

run_command cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

run_command cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# Gettext
cd /sources/gettext-0.24

run_command ./configure --disable-shared

run_command make && cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

# Bison
cd /sources/bison-3.8.2

run_command ./configure --prefix=/usr				\
			--docdir=/usr/share/doc/bison-3.8.2

run_command make && run_command make install

# Perl
cd /sources/perl-5.40.1

run_command sh Configure -des                                          	\
             		  -D prefix=/usr                               	\
             		  -D vendorprefix=/usr                         	\
             		  -D useshrplib                                	\
             		  -D privlib=/usr/lib/perl5/5.40/core_perl     	\
             		  -D archlib=/usr/lib/perl5/5.40/core_perl     	\
             		  -D sitelib=/usr/lib/perl5/5.40/site_perl     	\
             		  -D sitearch=/usr/lib/perl5/5.40/site_perl    	\
             		  -D vendorlib=/usr/lib/perl5/5.40/vendor_perl 	\
             		  -D vendorarch=/usr/lib/perl5/5.40/vendor_perl

run_command make && run_command make install

# Python
cd /sources/Python-3.13.2

run_command ./configure --prefix=/usr   \
            		--enable-shared \
            		--without-ensurepip

run_command make && run_command make install

# Texinfo
cd /sources/texinfo-7.2

run_command ./configure --prefix=/usr

run_command make && run_command make install

# Util-linux
mkdir -pv /var/lib/hwclock
cd /sources/util-linux-2.40.4

run_command ./configure --libdir=/usr/lib     				\
            		--runstatedir=/run    				\
            		--disable-chfn-chsh   				\
            		--disable-login       				\
            		--disable-nologin     				\
            		--disable-su          				\
            		--disable-setpriv     				\
            		--disable-runuser     				\
            		--disable-pylibmount  				\
            		--disable-static      				\
            		--disable-liblastlog2 				\
            		--without-python      				\
            		ADJTIME_PATH=/var/lib/hwclock/adjtime 		\
            		--docdir=/usr/share/doc/util-linux-2.40.4

run_command make && run_command make install

# Cleanup
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
