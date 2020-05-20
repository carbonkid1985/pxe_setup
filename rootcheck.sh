check_root() {
#
# syntax: check_root
#
# Checks if script is been run as root and returns 0 (root)/1 (not root).
#
# Returned variable is accessed with $?
#
# eg.
#
# check_root
#
# if [[ $? != "0" ]]; then                                                        #Checks$
#    printf "%s\n" "You need to have root privilages to run this script"
#    exit 0
# fi
#

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
#   echo "Not running as root"
   return 1
else
   return 0
fi
}
