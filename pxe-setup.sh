#! /bin/bash

source functions.sh

## global vars
tftpd_conf="/etc/default/tftpd-hpa"
dhcpd_conf="/etc/dhcp/dhcpd.conf"
tftp_dir="/data/tftpboot/"
syslinux_dir="/usr/lib/syslinux/modules/bios/"
pxelinux_dir="/usr/lib/PXELINUX/"
splash_image="https://i.imgur.com/ktEA3WS.png"

ensure_root (){
	check_root

	if [[ $? != "0"  ]]; then # returns 0 if root
     		output "You need to be root" red
		exit 0
	fi
}

setup_unattended(){

if [[ ! -f "${tftp_dir}pxelinux.cfg/pxe.conf" ]]; then

	confirm "Configure pxemenu conf file?"
	if [[ $? == "0" ]]; then # if yes
		pxemenu_flag="0"
	else 
		pxemenu_flag="1"
	fi
	
	confirm "Pull down background image?"
	if [[ $? == "0" ]]; then # if yes
		dl_splash="0"
	else
		dl_splash="1"
	fi
fi

	confirm "Install tftpd-hpa?"
	if [[ $? == "0" ]]; then # if yes
		install_tftp="0"
	else
		install_tftp="1"
	fi
	
	confirm "Install isc-dhcpd"
	if [[ $? == "0" ]]; then # if yes
		install_dhcp="0"
	else
		install_dhcp="1"
	fi
	
	confirm "Install nfs-kernel-server"
	if [[ $? == "0" ]]; then # if yes
		install_nfs="0"
	else
		install_nfs="1"
	fi

	confirm "Install syslinux?"
	if [[ $? == "0" ]]; then # if yes
		install_syslinux="0"
	else
		install_syslinux="1"
	fi

     	confirm "Install pxelinux?"
      	if [[ $? == "0" ]]; then # if yes
		install_pxelinux="0"
	else
		install_pxelinux="1"
	fi
}

conf_details (){

if [[ ${pxemenu_flag} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "SETUP PXELINUX BASE CONFIG = ${msg}" green

if [[ ${dl_splash} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "DOWNLOAD SPLASH IMAGE = ${msg}" green

if [[ ${install_tftp} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "INSTALL TFTP-HPA = ${msg}" green

if [[ ${install_dhcp} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "INSTALL ISC-DHCP = ${msg}" green

if [[ ${install_nfs} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "INSTALL NFS-KERNEL-SERVER = ${msg}" green

if [[ ${install_syslinux} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "INSTALL SYSLINUX = ${msg}" green

if [[ ${install_pxelinux} == "0" ]]; then
	msg="true"
else
	msg="false"
fi
output "INSTALL PXELINUX = ${msg}" green

confirm	"Would you like to proceed? press 'Y' to initiate the unattended setup of the pxe server, press 'N' to edit any details, or 'Q' to quit:"
#	if [[ $? != "0" ]]; then  #if anything but yes is returned
#		$0
#		exit 0
#	fi
ans=$?
	if [[ ${ans} == "1" ]]; then  #if anything but yes is returned
		$0
		exit 0
	elif [[ ${ans} == "2" ]]; then #if quit is entered
		echo "Goodbye!"
		exit 0
	fi
}

filestructure_setup (){
	if [[ ! -f "${tftp_dir}pxelinux.cfg/" ]]; then
		output "Creating file structure" green
 		mkdir -p ${tftp_dir}pxelinux.cfg
	fi
 	output "Creating pxe menu conf" green
	cat > "${tftp_dir}pxelinux.cfg/pxe.conf" << EOF
MENU TITLE  Pavey's PXE Server
MENU BACKGROUND pxelinux.cfg/pxe_splash.png
NOESCAPE 1
ALLOWOPTIONS 1
PROMPT 0
menu width 80
menu rows 14
MENU TABMSGROW 24
MENU MARGIN 10
menu color title		1;36;44		#ff8950fc #00000000 std
menu color sel			7;37;40		#ff8950fc #00000000 std
menu color unsel		37;44		#c04f4e63 #00000000 std
menu color help			37;40		#c0ffffff #00000000 std
menu color border		51;153;255	#00ffffff #00000000 none
EOF
	search "vesamenu.c32" "${tftp_dir}pxelinux.cfg/default"
	if [[ -f "${tftp_dir}pxelinux.cfg/default" ]] || [[ $? != "0" ]]; then
		output "Creating default menu" green
	cat > "${tftp_dir}pxelinux.cfg/default" << EOF
DEFAULT vesamenu.c32 
TIMEOUT 50
ONTIMEOUT BootLocal
PROMPT 0
MENU INCLUDE pxelinux.cfg/pxe.conf
NOESCAPE 1

LABEL BootLocal
        localboot 0
        TEXT HELP
        Boot from local hard disk
ENDTEXT

EOF
	fi
}

download_splash(){
	wget $splash_image -O /tmp/pxe_splash.png
	if [[ -f "/tmp/pxe_splash.png" ]]; then
		mv /tmp/pxe_splash.png ${tftp_dir}pxelinux.cfg/pxe_splash.png
		output "File saved in ${tftp_dir}pxelinux.cfg/pxe_splash.png" green
	else
		output "Error downloading image" red
	fi
}

tftpd_setup (){
      	output "Installing TFTPD" green
	apt install -y tftpd-hpa
	output "Modifying ${tftpd_conf}" green
	cat > "${tftpd_conf}" << EOF
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/data/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --verbose"
EOF
#	fi
}

dhcpd_setup (){
		output "Installing DHCPD" green
		apt install -y isc-dhcp-server
		output "Modifying ${dhcpd_conf}" green
	cat > "${dhcpd_conf}" << EOF
# dhcpd.conf

default-lease-time 600;
max-lease-time 7200;

authoritatve;

# DHCP declaration including PXE boot filename

subnet 192.168.0.0 netmask 255.255.255.0 {
        range 192.168.0.10 192.168.0.254;
        default-lease-time 21600;
        max-lease-time 43200;
        next-server 192.168.0.2;
        option routers 192.168.0.1;
        option domain-name-servers 192.168.0.2;
        filename "/lpxelinux.0";
}
EOF
}

nfs_setup (){
		output "Installing NFS" green
		apt install -y nfs-kernel-server
}

syslinux_setup (){
		output "Installing syslinux" green
		apt install -y syslinux
		output "Copy required files from ${syslinux_dir}" green
		cp -a ${syslinux_dir}. ${tftp_dir}
}

pxelinux_setup (){
     		output "Installing pxelinux" green
     		apt install -y pxelinux
     		output "Copy required files from ${pxelinux_dir}" green
     		cp -a ${pxelinux_dir}lpxelinux.0 ${tftp_dir}
}

## Start of script

ensure_root

setup_unattended

conf_details

if [[ ${pxemenu_flag} == "0" ]]; then
	filestructure_setup
fi

if [[ ${dl_splash} == "0" ]]; then
	download_splash
fi

if [[ ${install_tftp} == "0" ]]; then
	tftpd_setup
fi

if [[ ${install_dhcp} == "0" ]]; then
	dhcpd_setup
fi

if [[ ${install_nfs} == "0" ]]; then
	nfs_setup
fi

if [[ ${install_syslinux} == "0" ]]; then
	syslinux_setup
fi

if [[ ${install_pxelinux} == "0" ]]; then
	pxelinux_setup
fi

