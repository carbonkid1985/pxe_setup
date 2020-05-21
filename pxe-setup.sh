#! /bin/bash

source menus.sh
source rootcheck.sh

## global vars
#nfs_server_ip=192.168.0.2
tftpd_conf="/etc/default/tftpd-hpa"
dhcpd_conf="/etc/dhcp/dhcpd.conf"
tftp_dir="/data/tftpboot/"
syslinux_dir="/usr/lib/syslinux/modules/bios/"
pxelinux_dir="/usr/lib/PXELINUX/"
#mount_point="/mnt"

tftpd_setup ()
{
   confirm "Install tftpd-hpa?"
   if [[ $? == "0" ]]; then # if yes
      printf "%s\n" "Installing TFTPD"
      apt install tftpd-hpa
      printf "%s\n" "Modifying ${tftpd_conf}"
      cat > "${tftpd_conf}" << EOF
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/data/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --verbose"
EOF
   fi
}

dhcpd_setup ()
{
   confirm "Install isc-dhcpd"
   if [[ $? == "0" ]]; then # if yes
      printf "%s\n" "Installing DHCPD"
      apt install isc-dhcp-server
      printf "%s\n" "Modifying ${dhcpd_conf}"
      cat > "${dhcpd_conf}" << EOF
# dhcpd.conf

default-lease-time 600;
max-lease-time 7200;

authoritave;

# DHCP declaration including PXE boot filename

subnet 192.168.0.0 netmask 255.255.255.0 {
        range 192.168.0.10 192.168.0.254;
        default-lease-time 21600;
        max-lease-time 43200;
        next-server 192.168.0.2;
        option routers 192.168.0.1;
        option domain-name-servers 192.168.0.2;
        filename "/lpxelinux.0"
}
EOF
   fi
}

syslinux_setup ()
{
   confirm "Install syslinux?"
   if [[ $? == "0" ]]; then # if yes
      printf "%s\n" "Installing syslinux"
      apt install syslinux
      printf "%s\n" "Copy required files from ${syslinux_dir}"
      cp -a ${syslinux_dir}. ${tftp_dir}
   fi
}

pxelinux_setup ()
{
   confirm "Install pxelinux?"
   if [[ $? == "0" ]]; then # if yes
      printf "%s\n" "Installing pxelinux"
      apt install pxelinux
      printf "%s\n" "Copy required files from ${pxelinux_dir}"
      cp -a ${pxelinux_dir}/lpxelinux.0 ${tftp_dir}
   fi
}
## Start of script

check_root

if [[ $? != "0"  ]]; then # returns 0 if root
   printf "%s\n" "You need to be root"
   exit 0
fi

if [[ ! -d ${tftp_dir} ]]; then
   printf "%s\n" "Creating ${tftp_dir}"
   mkdir -p ${tftp_dir}
fi

tftpd_setup
dhcpd_setup
syslinux_setup
pxelinux_setup


