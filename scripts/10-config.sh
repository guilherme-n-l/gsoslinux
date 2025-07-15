#!/bin/bash

[ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo bash $(basename $0)\`" ; exit 1; }


# Network
systemctl disable systemd-networkd-wait-online
systemctl disable systemd-resolved

echo "gsoslinux" > /etc/hostname

cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost
::1       localhost

# End /etc/hosts
EOF

# Clock
cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

# Console
echo FONT=Lat2-Terminus16 > /etc/vconsole.conf

# Locale
echo LANG=en_US.utf8 > /etc/locale.conf

cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF

# Inputrc
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

# Shells
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

# Boot
rootFs="/dev/sda3"
swapFs="/dev/sda2"
bootFs="/dev/sda1"

cat > /etc/fstab << EOF
# Begin /etc/fstab

# file system	mount-point	type     	options             											dump	fsck

$rootFs		/		ext4		defaults            											1	1
$swapFs		swap		swap		pri=1													0	0
$bootFs		/boot		vfat		rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0	2

# End /etc/fstab
EOF

install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

insmod efi_gop
insmod efi_uga
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, Linux 6.13.2-lfs-12.3" {
  linux   /boot/vmlinuz-6.13.2-lfs-12.3 root=/dev/sda2 ro
}

menuentry "Firmware Setup" {
  fwsetup
}
EOF
