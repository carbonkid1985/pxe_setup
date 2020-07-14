#! /bin/bash

source functions.sh

## global vars

nfs_server_ip=192.168.0.2
tftp_dir="/data/tftpboot"
ubuntu_dir="${tftp_dir}/ubuntu/desktop"
mount_point="/mnt"
menu_str="${ubuntu_dir}/desktop.menu"
menu_path="${tftp_dir}/ubuntu/ubuntu.menu"
default_menu="${tftp_dir}/pxelinux.cfg/default"

## functions

output(){
case $2 in
	0)
		printf "\n\e[31;1m%s\e[0m\n" "$1" # Bright red
		;;	
	1)
		printf "\e[31;1m%s\e[0m\n" "$1" # Bright red no pre crlf
		;;
	2)
		printf "\n\e[32;1m%s\e[0m\n" "$1" # Bright green
		;;
	3)
		printf "\e[32;1m%s\e[0m\n" "$1" # Bright green no pre crlf 
		;;
	4)
		printf "\n\e[34;1m%s\e[0m\n" "$1" # Bright blue
		;;
	5)
		printf "\n\e[35;1m%s\e[0m\n" "$1" # Bright magenta
		;;
	*)
		printf "\n\e[0m%s\n" "No formatting option!"
		;;
esac

}

menu_1 ()
{

title="Select Ubuntu flavour"
prompt="Pick an option:"
options=("Ubuntu"
	 "Xubuntu"
	 "Lubuntu"
	 "Kubuntu"
	 "Ubuntu Mate"
	 "Ubuntu Budgie"
 	 "Other")

#printf "%s\n" "${title}"
output "${title}" 2
PS3="${prompt} "
select opt in "${options[@]}" "Quit"; do

   case "${REPLY}" in

   1 ) flavour="ubuntu"; de="gnome"; menu_flavour="${flavour^}"; menu_de="${de^}";;
   2 ) flavour="xubuntu"; de="xfce"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   3 ) flavour="lubuntu"; de="lxde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   4 ) flavour="kubuntu"; de="kde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
   5 ) flavour="ubuntu_mate"; de="mate"; menu_flavour="Ubuntu Mate"; menu_de="${de^^}";;
   6 ) flavour="ubuntu_budgie"; de="budgie"; menu_flavour="Ubuntu Budgie"; menu_de="${de^}";;
   7 ) flavour="other";;
   $(( ${#options[@]}+1 )) ) printf "%s\n" "Goodbye!"; exit 0;;
   #*) printf "%s\n" "Invalid option. Try another one.";continue;;
   *) output "Invalid option. Try another one." 0;continue;;

   esac

   if [[ ${flavour} == "other"  ]]; then
	prompt="Enter ubuntu flavor: "
	read -p "${prompt}" flavour

	while [ -z ${flavour}  ]; do
		#printf "%s\n" "No input entered"
		output "No input entered" 1
		read -p "${prompt}" flavour
	done
	
	prompt="Enter desktop environment: "
	read -p "${prompt}" de

	while [ -z ${de} ]; do
		#printf "%s\n" "No input entered"
		output "No input entered" 1
		read -p "${prompt}" de
	done

	menu_flavour="${flavour^}"
	menu_de="${de^}"
   fi

#printf "You selected %s\n\n" "${opt}"
output "You selected ${opt}" 4
break
done
}

menu_2 ()
{

prompt="Enter version number: "

read -p "${prompt}" version

while [ -z ${version} ]; do
   #printf "%s\n" "No input entered"
   output "No input entered" 1
   read -p "${prompt}" version
done

#printf "You entered %s\n\n" "${version}"
output "You entered ${version}" 4
}

menu_3 ()
{
#printf "%s\n\n" "See details entered below:"
#printf "%s\n" "URL = ${url}"
#printf "%s\n" "FILE = ${file}" #debug
#printf "%s\n" "ISO = ${iso}"
#printf "%s\n" "FLAVOUR = ${flavour}"
#printf "%s\n" "MENU FLAVOUR = ${menu_flavour}" #debug
#printf "%s\n" "DESKTOP = ${de}"
#printf "%s\n" "MENU DESKTOP = ${menu_de}" #debug
#printf "%s\n" "VERSION = ${version}"

output "See details entered below:" 4
output "URL = ${url}" 2
#output "FILE = ${file}" 3 #debug
output "ISO = ${iso}" 3
output "FLAVOUR = ${flavour}" 3
#output "MENU FLAVOUR = ${menu_flavour}" 3 #debug 
output "DESKTOP = ${de}" 3
#output "MENU DESKTOP = ${menu_de}" 3 #debug
output "VERSION = ${version}" 3

confirm	"Are these details correct?"  #yes no question

if [[ $? != "0" ]]; then  #if anything but yes is returned
   #./$0 ${arg1}
   /$0 ${arg1}
   exit 0
fi
}

create_dir ()
{
   #printf "%s\n" "Creating path ${ubuntu_dir}/${version}/x64/${de}"
   output "Creating path ${ubuntu_dir}/${version}/x64/${de}" 4
   sudo mkdir -p "${ubuntu_dir}/${version}/x64/${de}"
}

mount_iso ()
{
   #printf "%s\n" "Mounting the ISO"
   output "Mounting the ISO" 4
   sudo mount -o loop,ro ${file} ${mount_point}
}

copy_files ()
{
   #printf "%s\n" "Copying loop files"
   output "Copying loop files" 4
   sudo cp -a ${mount_point}/. "${ubuntu_dir}/${version}/x64/${de}"
}

umount_iso ()
{
   #printf "%s\n" "Unmounting the ISO"
   output "Unmounting the ISO" 4
   sudo umount ${mount_point}
}

append_menu ()
{
   search "menu begin ubuntu" "${default_menu}"
   if [[ $? != "0" ]]; then
      #printf "%s\n" "Adding default menu entry"
      output "Adding default menu entry" 4
      cat >> "${default_menu}" << EOF

MENU BEGIN Ubuntu
	MENU TITLE Ubuntu
        LABEL Previous
        MENU LABEL Previous Menu
        TEXT HELP
        Return to previous menu
        ENDTEXT
        MENU EXIT
        MENU SEPARATOR
        MENU INCLUDE ubuntu/ubuntu.menu
MENU END

EOF

   fi

   if [[ ! -f "${menu_path}" ]]; then
      #printf "%s\n" "Creating disto menu"
      output "Creating disto menu" 4
      cat > "${menu_path}" << EOF
# initrd path is relative to pxe root (/tftpboot)
# nfsroot ip is pxe server's address

EOF

   fi
   search "menu include ubuntu/desktop/desktop.menu" "${menu_path}"
   if [[ $? != "0" ]]; then 
      #printf "%s\n" "Adding distro menu entry"
      output "Adding distro menu entry" 4
      cat >> "${menu_path}" << EOF

MENU BEGIN Desktop
MENU TITLE Desktop
	LABEL Previous
	MENU LABEL Previous Menu
	TEXT HELP
	Return to previous menu
	ENDTEXT
	MENU EXIT
	MENU SEPARATOR
	MENU INCLUDE ubuntu/desktop/desktop.menu
MENU END

EOF

   fi
   
   if [[ ! -f "${menu_str}" ]]; then
      #printf "%s\n" "Creating flavour menu"
      output "Creating flavour menu" 4
      cat > "${menu_str}" << EOF
# initrd path is relative to pxe root (/tftpboot)
# nfsroot ip is pxe server's address

EOF

   fi  

   search "menu label ${menu_flavour} ${version} x64 ${menu_de}" "${menu_str}"
   if [[ $? != "0" ]]; then
      #printf "%s\n" "Adding flavour menu entry"
      #printf -v rand "%05d" $((1 + RANDOM % 32767))
      output "Adding flavour menu entry" 4
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

   fi
}

append_exports ()
{
   #printf "%s\n" "Adding entry to exports"
   output "Adding entry to exports" 4
   echo "${ubuntu_dir}/${version}/x64/${de}/		192.168.0.0/24(ro,async,no_subtree_check)" >> /etc/exports
}

## Start of script

check_root

if [[ $? != "0" ]]; then  #Checks for root
   #printf "%s\n" "You need to have root privilages to run this script"
   output "You need to have root privilages to run this script!" 0; exit 0
fi

if [[ ! -z $1 ]]; then
   arg1=$1

   if [[ -f ${arg1} ]]; then
      file=${arg1}
      #printf "%s\n" "Local file ${file} found."
      output "Local file ${file} found." 4
   else
      url=${arg1}
      #printf "%s\n" "No local file found, URL assumed, ${url}."
      output "No local file found, URL assumed, ${url}." 4
#      wget ${url} -P /tmp
      file=/tmp/${url##*/}
   fi
else
   #printf "%s\n" "Usage: pxe-release-ubuntu.sh [local iso file or URL]..."; exit 0
   output "Usage: pxe-release-ubuntu.sh [local iso file or URL]..." 4; exit 0
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
      #printf "%s\n" "Download started"
      output "Download started" 4
      wget ${url} -O /tmp/${iso}

      if [[ ! -f ${file} ]]; then
         #printf "%s\n" "Unable to find downloaded file. Please check URL"; exit 0
         output "Unable to find downloaded file. Please check URL" 0; exit 0
      fi
   fi
fi

confirm "would you like the filesystem created?"  #yes no question

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
   #printf "%s\n" "Restarting nfs server"
   output "Restarting nfs server" 4
   sudo systemctl restart nfs-kernel-server.service
fi

if [[ -f ${file} ]]; then
	
   confirm "Would you like to delete the local iso?"  #yes no question

   if [[ $? == "0" ]]; then  #if yes
      #printf "%s\n" "Deleting local iso file ${file}"
      output "Deleting local iso file ${file}" 4
      sudo rm ${file}
   fi
fi

output "Success! All operations completed" 2
