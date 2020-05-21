#! /bin/bash

source menus.sh
source rootcheck.sh

## global vars
#nfs_server_ip=192.168.0.2
#ubuntu_dir="/data/tftpboot/ubuntu/desktop"
#mount_point="/mnt"

tftpd_setup ()
{
   confirm "Install tftpd-hpa?"
   if [[ $? == "0" ]]; then # if yes
      printf "%s\n" "Install TFTPD"
   fi
}

## Start of script

check_root

if [[ $? != "0"  ]]; then # returns 0 if root
   printf "%s\n" "You need to be root"
   exit 0
fi

tftpd_setup
