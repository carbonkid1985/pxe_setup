#! /bin/bash

source menus.sh
source rootcheck.sh

## global vars
nfs_server_ip=192.168.0.2
ubuntu_dir="/data/tftpboot/ubuntu/desktop"
mount_point="/mnt"

## functions

menu_1 ()
{

title="Select Ubuntu flavour"
prompt="Pick an option:"
options=("Ubuntu"
	 "Xubuntu"
	 "Lubuntu"
	 "Kubuntu"
	 "Ubuntu Mate"
	 "Ubuntu Budgie")

printf "%s\n" "${title}"
PS3="${prompt} "
select opt in "${options[@]}" "Quit"; do

   case "${REPLY}" in

   1 ) flavour="ubuntu"; de="gnome"; menu_flavour="${flavour^}"; menu_de="${de^}";;
   2 ) flavour="xubuntu"; de="xfce"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   3 ) flavour="lubuntu"; de="lxde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   4 ) flavour="kubuntu"; de="kde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   5 ) flavour="ubuntu_mate"; de="mate"; menu_flavour="Ubuntu Mate"; menu_de="${de^^}";;
   6 ) flavour="ubuntu_budgie"; de="budgie"; menu_flavour="Ubuntu Budgie"; menu_de="${de^}";;
   $(( ${#options[@]}+1 )) ) printf "%s\n" "Goodbye!"; exit 0;;
   *) printf "%s\n" "Invalid option. Try another one.";continue;;

   esac
printf "You selected %s\n\n" "${opt}"
break
done
}

menu_2 ()
{

prompt="Enter version number:"

read -p "${prompt} " version

while [ -z ${version} ]; do
   printf '%s\n' "No input entered"
   read -p "${prompt} " version
done

printf "You entered %s\n\n" "${version}"
}

menu_3 ()
{
printf "%s\n\n" "See details entered below:"

printf "%s\n" "URL = ${url}"
#printf "%s\n" "FILE = ${file}"
printf "%s\n" "ISO = ${iso}"
printf "%s\n" "FLAVOUR = ${flavour}"
#printf "%s\n" "MENU FLAVOUR = ${menu_flavour}"
printf "%s\n" "DESKTOP = ${de}"
#printf "%s\n" "MENU DESKTOP = ${menu_de}"
printf "%s\n" "VERSION = ${version}"

confirm	"Are these details correct?"  #yes no question

if [[ $? != "0" ]]; then  #if anything but yes is returned
   ./$0 ${arg1}
   exit 0
fi
}

create_dir ()
{
   printf "%s\n" "Creating path ${ubuntu_dir}/${version}/x64/${de}"
   sudo mkdir -p "${ubuntu_dir}/${version}/x64/${de}"
}

mount_iso ()
{
   printf "%s\n" "Mounting the ISO"
   sudo mount -o loop,ro ${file} ${mount_point}
}

copy_files ()
{
   printf "%s\n" "Copying loop files"
   sudo cp -a ${mount_point}/. "${ubuntu_dir}/${version}/x64/${de}"
}

umount_iso ()
{
   printf "%s\n" "Unmounting the ISO"
   sudo umount ${mount_point}
}

append_menu ()
{
   printf "%s\n" "Adding menu entry"
   printf -v rand "%05d" $((1 + RANDOM % 32767))
   cat >> "${ubuntu_dir}/desktop.menu" << EOF
LABEL ${rand}
	MENU LABEL ${menu_flavour} ${version} x64 ${menu_de}
	KERNEL /ubuntu/desktop/${version}/x64/${de}/casper/vmlinuz
	INITRD /ubuntu/desktop/${version}/x64/${de}/casper/initrd
	APPEND ip=dhcp boot=casper text vga=normal netboot=nfs nfsroot=${nfs_server_ip}:${ubuntu_dir}/${version}/x64/${de} splash --
	TEXT HELP
	Boot ${menu_flavour} ${version} x64 ${menu_de}
ENDTEXT

EOF

}

append_exports ()
{
   printf "%s\n" "Adding entry to exports"
   echo "${ubuntu_dir}/${version}/x64/${de}/		192.168.0.0/24(ro,async,no_subtree_check)" >> /etc/exports
}

## Start of script

check_root

if [[ $? != "0" ]]; then  #Checks for root
   printf "%s\n" "You need to have root privilages to run this script"
   exit 0
fi

if [[ ! -z $1 ]]; then
   arg1=$1

   if [[ -f ${arg1} ]]; then
      file=${arg1}
      printf "%s\n" "Local file ${file} found."
   else
      url=${arg1}
      printf "%s\n" "No local file found, URL assumed, ${url}."
#      wget ${url} -P /tmp
      file=/tmp/${url##*/}
   fi
else
   printf "%s\n" "Usage: pxe.sh {local iso file or URL}"; exit 0
fi

# set parameter
iso=${file##*/}
#distro=${iso%.*}

menu_1

menu_2

menu_3

if [ ! -z ${url} ]; then  ## if the image is a URL go ahead and attempt to download
   confirm "Would you like to download the iso?"  #yes no question

   if [[ $? == "0" ]]; then  #if yes
      printf "%s\n" "Download started"
      wget ${url} -P /tmp

      if [[ ! -f ${file} ]]; then
         printf "%s\n" "Unable to find downloaded file. Please check URL"; exit 0
      fi
   fi
fi

confirm "Would you like the filesystem created?"  #yes no question

if [[ $? == "0" ]]; then  #if yes
   create_dir
   mount_iso
   copy_files
   umount_iso
fi

confirm "Would you like a PXE menu entry added?"  #yes no question

if [[ $? == "0" ]]; then  #if yes
   append_menu
fi

confirm "Would you like to add an entry to the exports file?"  #yes no question

if [[ $? == "0" ]]; then  #if yes
   append_exports
   printf "%s\n" "Restarting nfs server"
   sudo systemctl restart nfs-kernel-server.service
fi

confirm "Would you like to delete the local iso?"  #yes no question

if [[ $? == "0" ]]; then  #if yes
   printf "%s\n" "Deleting local iso file ${file}"
   sudo rm ${file}
fi
