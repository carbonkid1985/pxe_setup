#! /bin/bash

source functions.sh

## global vars ##

nfs_server_ip="192.168.0.2"
tftp_dir="/data/tftpboot"
mount_point="/mnt"
ubuntu_dir="${tftp_dir}/ubuntu"
desktop_dir="${ubuntu_dir}/desktop"
server_dir="${ubuntu_dir}/server"
menu_path="${ubuntu_dir}/ubuntu.menu"
type_menu_path="${server_dir}/server.menu"
default_menu="${tftp_dir}/pxelinux.cfg/default"

## functions

ensure_root ()
{
	check_root

	if [[ $? != "0" ]]; then  #Checks for root
		output "You need to have root privilages to run this script!" red
		exit 0
	fi
}

check_arg ()
{
	if [[ ! -z $1 ]]; then
		arg=$1
	
		if [[ -f ${arg} ]]; then
			file=${arg}
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
			url_file="1"
		else
			url=${arg}
			output "No local file found, URL assumed, ${url}." blue
			file=/tmp/${url##*/}
			url_file="0"
		fi
		iso=${file##*/}
	else
		output "ERROR! Usage: pxe-release-ubuntu-server.sh [local iso file or URL]..." red
		exit 0
	fi
}

select_flavour ()
{
	title="Select Ubuntu flavour"
	prompt="Pick an option:"
	options=("Netboot"
		"Full ISO")
#		"Other")
		
	output "${title}" green
	PS3="${prompt} "
	select opt in "${options[@]}" "Quit"; do
		case "${REPLY}" in
			1) flavour="netboot"; de="netboot"; menu_flavour="${flavour^}"; menu_de="${de^}";;
			2) flavour="full_iso"; de="loop"; menu_flavour="Full ISO"; menu_de="${de^^}";;
#			3) flavour="other";;
			$(( ${#options[@]}+1 )) ) output "Goodbye!" green; exit 0;;
			*) output "Invalid option. Try another one." red;continue;;
	
		esac
			
#		if [[ ${flavour} == "other"  ]]; then
#			prompt="Enter ubuntu flavor: "
#			read -p "${prompt}" flavour
#				
#			while [[ -z ${flavour}  ]]; do
#				output "No input entered" red
#				read -p "${prompt}" flavour
#			done
#
#			prompt="Enter desktop environment: "
#			read -p "${prompt}" de
#
#			while [[ -z ${de} ]]; do
#				output "No input entered" red
#				read -p "${prompt}" de
#			done
#			menu_flavour="${flavour^}"
#			menu_de="${de^}"
#		fi
		output "You entered: ${flavour^}" blue
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
	
	output "You entered: ${version}" blue
}

dl_file ()
{
	if [[ ! -z ${url} ]]; then  ## if the image is a URL
		confirm "Would you like to download the iso?"  #yes no question

		if [[ $? == "0" ]]; then  #if yes
			dl_flag="0"
		else
			dl_flag="1"
   		fi
	fi
}

fs_create ()
{
	confirm "would you like the filesystem created?"  #yes no question

	if [[ $? == "0" ]]; then #if yes
		fs_flag="0"
	else
		fs_flag="1"
	fi
}

pxe_menu ()
{
	confirm "Would you like a PXE menu entry added?"  #yes no question

	if [[ $? == "0" ]]; then  #if yes
		pxemenu_flag="0"
	else
		pxemenu_flag="1"
	fi
}

exports_add ()
{
	confirm "Would you like to add an entry to the exports file?"  #yes no question

	if [[ $? == "0" ]]; then  #if yes
		exports_flag="0"
	else
		exports_flag="1"
	fi
}

rm_iso ()
{
	confirm "Would you like to delete the local iso?"  #yes no question

	if [[ $? == "0" ]]; then  #if yes
		delete_flag="0"
	else
		delete_flag="1"
	fi
}

conf_details ()
{
	output "See details entered below:" blue
	if [[ ${url_file} == "0" ]]; then
		output "URL = ${url}" green
	else
		output "FILE = ${file}" green
	fi
	#output "URL = ${url}" green
	#output "FILE = ${file}" green #debug
	output "ISO = ${iso}" green
	output "FLAVOUR = ${flavour}" green
	#output "MENU FLAVOUR = ${menu_flavour}" green #debug 
	output "DESKTOP = ${de}" green
	#output "MENU DESKTOP = ${menu_de}" green #debug
	output "VERSION = ${version}" green
	
	if [[ ! -z ${url} ]]; then  ## if the image is a URL
		if [[ ${dl_flag} == "0" ]]; then
			msg="true"
		else
			msg="false"
		fi
		output "DOWNLOAD ISO = ${msg}" green
	fi

	if [[ ${fs_flag} == "0" ]]; then
		msg="true"
	else
		msg="false"
	fi
	output "CREATE & POPULATE FILE STRUCTURE = ${msg}" green

	if [[ ${pxemenu_flag} == "0" ]]; then
		msg="true"
	else
		msg="false"
	fi
	output "ADD ENTRY TO PXE MENU = ${msg}" green

	if [[ ${exports_flag} == "0" ]]; then
		msg="true"
	else
		msg="false"
	fi
	output "ADD ENTRY TO NFS EXPORTS FILE = ${msg}" green

	if [[ ${delete_flag} == "0" ]]; then
		msg="true"
	else
		msg="false"
	fi
	output "DELETE ISO FILE UPON COMPLETION = ${msg}" green

	confirm	"Would you like to proceed? press 'Y' to initiate the unattended release of the PXE image, press 'N' to edit any details:"  #yes no question
	if [[ $? != "0" ]]; then  #if anything but yes is returned
		#./$0 ${arg}
		#/$0 ${arg}
		$0 ${arg}
		exit 0
	fi
}

create_dir ()
{
	output "Creating path ${server_dir}/${version}/x64/${de}" blue
	sudo mkdir -p "${server_dir}/${version}/x64/${de}"
}

mount_iso ()
{
	output "Mounting the ISO" blue
	sudo mount -o loop,ro ${file} ${mount_point}
}

copy_files ()
{
	output "Copying loop files" blue
	sudo cp -a ${mount_point}/. "${server_dir}/${version}/x64/${de}"
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
	search "menu include ubuntu/server/server.menu" "${menu_path}"
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
	MENU INCLUDE ubuntu/server/server.menu
MENU END

EOF

	else
		output "WARNING! Distro menu entry already exists. Skipping" yellow 
	fi
   
	if [[ ! -f "${type_menu_path}" ]]; then
		output "Creating flavour menu" blue

cat > "${type_menu_path}" << EOF
# initrd path is relative to pxe root (/data/tftpboot)
# nfsroot ip is pxe server's address

EOF

   	fi  
	
	search "menu label ${menu_flavour} ${version} x64 ${menu_de}" "${type_menu_path}"
	if [[ $? != "0" ]]; then
		output "Adding flavour menu entry" blue
		printf -v rand "%05d" $((1 + RANDOM % 32767))

		if [[ ${flavour} == "netboot" ]]; then

cat >> "${server_dir}/server.menu" << EOF
LABEL ${rand}
	MENU LABEL Ubuntu ${version} Server x64 ${menu_flavour}
        KERNEL /ubuntu/server/${version}/x64/${de}/linux
        INITRD /ubuntu/server/${version}/x64/${de}/initrd.gz
	APPEND text vga=788 locale=en_GB.UTF-8 keyboard-configuration/layout=gb
        TEXT HELP
        Boot Ubuntu ${version} Server x64 ${menu_flavour}
ENDTEXT

EOF

#		elif [[ ${flavour} == "full_iso" ]]; then
		else
		
cat >> "${server_dir}/server.menu" << EOF
LABEL ${rand}
        MENU LABEL Ubuntu ${version} Server x64 ${menu_flavour}
        KERNEL /ubuntu/server/${version}/x64/${de}/casper/vmlinuz
        INITRD /ubuntu/server/${version}/x64/${de}/casper/initrd
        APPEND ip=dhcp boot=casper text vga=normal netboot=nfs nfsroot=${nfs_server_ip}:${server_dir}/${version}/x64/${de} locale=en_GB.UTF-8 keyboard-configuration/layout=gb splash
        TEXT HELP
	Boot Ubuntu ${version} Server x64 ${menu_flavour}
ENDTEXT

EOF
		fi
	else
		output "WARNING! Flavour menu entry already exists. Skipping" yellow 
	fi
}

append_exports ()
{
	search  "${server_dir}/${version}/x64/${de}/" "/etc/exports"
	if [[ $? != "0" ]]; then
		output "Adding entry to exports" blue
		echo "${server_dir}/${version}/x64/${de}/		192.168.0.0/24(ro,async,no_subtree_check)" >> /etc/exports
	else
		output "WARNING! NFS Exports entry already exists. Skipping" yellow 
	fi
	}

### Start of script ###

ensure_root
check_arg $1

# set parameter

select_flavour
select_version
dl_file
fs_create
pxe_menu
exports_add
rm_iso
conf_details

if [[ ! -z ${url} ]]; then
	if [[ ${dl_flag} == "0" ]]; then  #if yes
		output "Download started" blue
		wget ${url} -O /tmp/${iso}

		if [[ ! -f ${file} ]]; then
       		output "Unable to find downloaded file. Please check URL" red; exit 0
   		fi
	fi
fi

if [[ ${fs_flag} == "0" ]]; then  #if yes
   	create_dir
   	mount_iso
   	copy_files
   	umount_iso
fi

if [[ ${pxemenu_flag} == "0" ]]; then  #if yes
   	append_menu
fi

if [[ ${exports_flag} == "0" ]]; then  #if yes
   	append_exports
   	output "Restarting nfs server" blue
   	sudo systemctl restart nfs-kernel-server.service
fi

if [[ -f ${file} ]]; then
	if [[ ${delete_flag} == "0" ]]; then  #if yes
		output "Deleting local iso file ${file}" blue
     		sudo rm ${file}
	fi
fi

output "Success! All operations completed" green
exit 0