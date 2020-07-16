#! /bin/bash

source functions.sh

## global vars
#nfs_server_ip=192.168.0.2
tftpd_conf="/etc/default/tftpd-hpa"
dhcpd_conf="/etc/dhcp/dhcpd.conf"
tftp_dir="/data/tftpboot/"
syslinux_dir="/usr/lib/syslinux/modules/bios/"
pxelinux_dir="/usr/lib/PXELINUX/"
#mount_point="/mnt"

filestructure_setup ()
{
     	if [[ ! -f "${tftp_dir}pxelinux.cfg/pxe.conf" ]]; then
	       	confirm "Configure default menu structure?"
		if [[ $? == "0" ]]; then # if yes
	       		printf "%s\n" "Creating file structure"
		 	mkdir -p ${tftp_dir}pxelinux.cfg
		 	confirm "Create pxe menu conf file?"
		     	if [[ $? == "0" ]]; then # if yes
		       		printf "%s\n" "Creating pxe menu conf"
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
			fi
			search "vesamenu.c32" "${tftp_dir}pxelinux.cfg/default"
			if [[ $? != "0" ]]; then # if not present
				printf "%s\n" "Creating default menu"
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
			confirm "Pull down background image?"
			if [[ $? == "0" ]]; then # if yes
				wget https://i.imgur.com/ktEA3WS.png -O /tmp/pxe_splash.png
				if [[ -f "/tmp/pxe_splash.png" ]]; then
					printf "%s\n" "File saved in ${tftp_dir}pxelinux.cfg/pxe_splash.png"  
					mv /tmp/pxe_splash.png ${tftp_dir}pxelinux.cfg/pxe_splash.png
				else
					printf "%s\n" "Error downloading image"
				fi
			fi 
		fi
	fi
}

#services_setup ()
#{
#}

tftpd_setup ()
{
	confirm "Install tftpd-hpa?"
	if [[ $? == "0" ]]; then # if yes
	       	printf "%s\n" "Installing TFTPD"
		apt install -y tftpd-hpa
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
		apt install -y isc-dhcp-server
		printf "%s\n" "Modifying ${dhcpd_conf}"
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
	fi
}

dhcpd_setup ()
{
	confirm "Install nfs-kernel-server"
	if [[ $? == "0" ]]; then # if yes
		printf "%s\n" "Installing NFS"
		apt install -y nfs-kernel-server
	fi
}
syslinux_setup ()
{
	confirm "Install syslinux?"
	if [[ $? == "0" ]]; then # if yes
		printf "%s\n" "Installing syslinux"
		apt install -y syslinux
		printf "%s\n" "Copy required files from ${syslinux_dir}"
		cp -a ${syslinux_dir}. ${tftp_dir}
	fi
}

pxelinux_setup ()
{
     	confirm "Install pxelinux?"
      	if [[ $? == "0" ]]; then # if yes
     		printf "%s\n" "Installing pxelinux"
     		apt install -y pxelinux
     		printf "%s\n" "Copy required files from ${pxelinux_dir}"
     		cp -a ${pxelinux_dir}lpxelinux.0 ${tftp_dir}
	fi
}
## Start of script

check_root

if [[ $? != "0"  ]]; then # returns 0 if root
     	printf "%s\n" "You need to be root"
	exit 0
fi

confirm "Setup filestructure"
if [[ $? == "0" ]];then
	filestructure_setup
fi

confirm "Install services?"
if [[ $? == "0" ]]; then # if yes
  	tftpd_setup
    	dhcpd_setup
      	nfs_setup
	syslinux_setup
      	pxelinux_setup
fi
