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

select_flavour ()
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
		
	output "${title}" green
	PS3="${prompt} "
	select opt in "${options[@]}" "Quit"; do
		case "${REPLY}" in
			1) flavour="ubuntu"; de="gnome"; menu_flavour="${flavour^}"; menu_de="${de^}";;
			2) flavour="xubuntu"; de="xfce"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
			3) flavour="lubuntu"; de="lxde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
			4) flavour="kubuntu"; de="kde"; menu_flavour="${flavour^}"; menu_de="${de^^}";;
			5) flavour="ubuntu_mate"; de="mate"; menu_flavour="Ubuntu Mate"; menu_de="${de^^}";;
			6) flavour="ubuntu_budgie"; de="budgie"; menu_flavour="Ubuntu Budgie"; menu_de="${de^}";;
			7) flavour="other";;
			$(( ${#options[@]}+1 )) ) output "Goodbye!" green; exit 0;;
			*) output "Invalid option. Try another one." red;continue;;
	
		esac
			
		if [[ ${flavour} == "other"  ]]; then
			prompt="Enter ubuntu flavor: "
			read -p "Enter ubuntu flavour" flavour
				
			while [ -z ${flavour}  ]; do
				output "No input entered" red
				read -p "${prompt}" flavour
			done
			prompt="Enter desktop environment: "
			read -p "${prompt}" de

			while [ -z ${de} ]; do
				output "No input entered" red
				read -p "${prompt}" de
			done
			menu_flavour="${flavour^}"
			menu_de="${de^}"
		fi
		output "You selected ${opt}" blue
		break
	done
}

select_version ()
{
	prompt="Enter version number: "
	read -p "${prompt}" version
	
	while [ -z ${version} ]; do
		output "No input entered" red
		read -p "${prompt}" version
	done
	
	output "You entered ${version}" blue
}

conf_details ()
{
	output "See details entered below:\n" blue
	output "URL = ${url}" green
	#output "FILE = ${file}" green #debug
	output "ISO = ${iso}" green
	output "FLAVOUR = ${flavour}" green
	#output "MENU FLAVOUR = ${menu_flavour}" green #debug 
	output "DESKTOP = ${de}" green
	#output "MENU DESKTOP = ${menu_de}" green #debug
	output "VERSION = ${version}" green

	confirm	"Are these details correct?"  #yes no question
	if [[ $? != "0" ]]; then  #if anything but yes is returned
		#./$0 ${arg1}
		/$0 ${arg1}
		exit 0
	fi
}

create_dir ()
{
	output "Creating path ${ubuntu_dir}/${version}/x64/${de}" blue
	sudo mkdir -p "${ubuntu_dir}/${version}/x64/${de}"
}

mount_iso ()
{
	output "Mounting the ISO" blue
	sudo mount -o loop,ro ${file} ${mount_point}
}

copy_files ()
{
	output "Copying loop files" blue
	sudo cp -a ${mount_point}/. "${ubuntu_dir}/${version}/x64/${de}"
}

umount_iso ()
{
	output "Unmounting the ISO" blue
	sudo umount ${mount_point}
}

append_menu ()
{
	search "menu begin ubuntu" "${default_menu}"
	if [[ $? != "0" ]]; then
		output "Adding default menu entry" blue

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
		output "Creating disto menu" blue

cat > "${menu_path}" << EOF
# initrd path is relative to pxe root (/tftpboot)
# nfsroot ip is pxe server's address

EOF

	fi
	search "menu include ubuntu/desktop/desktop.menu" "${menu_path}"
	if [[ $? != "0" ]]; then 
		output "Adding distro menu entry" blue

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
		output "Creating flavour menu" blue

cat > "${menu_str}" << EOF
# initrd path is relative to pxe root (/tftpboot)
# nfsroot ip is pxe server's address

EOF

   	fi  
	
	search "menu label ${menu_flavour} ${version} x64 ${menu_de}" "${menu_str}"
	if [[ $? != "0" ]]; then
		output "Adding flavour menu entry" blue
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
	output "Adding entry to exports" blue
	echo "${ubuntu_dir}/${version}/x64/${de}/		192.168.0.0/24(ro,async,no_subtree_check)" >> /etc/exports
}

### Start of script ###

check_root

if [[ $? != "0" ]]; then  #Checks for root
	output "You need to have root privilages to run this script!" red; exit 0
fi

if [[ ! -z $1 ]]; then
	arg1=$1
	
	if [[ -f ${arg1} ]]; then
		file=${arg1}
		ext=${file##*.}
		if [[ ${ext} == "iso" ]]; then
			output "Local file, ${file} found." blue
		else
			output "File specified does not appear to be an iso disk image." red
			confirm "Would you like to proceed."  #yes no question

			if [[ $? == "1" ]]; then  #if no
   				exit 0
			fi	
		fi
	else
		url=${arg1}
		output "No local file found, URL assumed, ${url}." blue
		file=/tmp/${url##*/}
	fi
	iso=${file##*/}
else
	output "Usage: pxe-release-ubuntu.sh [local iso file or URL]..." blue; exit 0
fi

# set parameter

select_flavour

select_version

conf_details

if [ ! -z ${url} ]; then  ## if the image is a URL go ahead and attempt to download
	confirm "Would you like to download the iso?"  #yes no question
	if [[ $? == "0" ]]; then  #if yes
		output "Download started" blue
		wget ${url} -O /tmp/${iso}

      		if [[ ! -f ${file} ]]; then
         		output "Unable to find downloaded file. Please check URL" red; exit 0
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
   	output "Restarting nfs server" blue
   	sudo systemctl restart nfs-kernel-server.service
fi

if [[ -f ${file} ]]; then
	
   	confirm "Would you like to delete the local iso?"  #yes no question

   	if [[ $? == "0" ]]; then  #if yes
      		output "Deleting local iso file ${file}" blue
      		sudo rm ${file}
   	fi
fi

output "Success! All operations completed" green
