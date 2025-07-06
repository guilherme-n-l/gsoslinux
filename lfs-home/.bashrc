set +h
umask 022
LFS=/mnt/lfs
LANG=POSIX
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin:/run/current-system/sw/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j12
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE MAKEFLAGS
