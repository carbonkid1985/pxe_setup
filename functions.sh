confirm() {
#
# syntax: confirm [<prompt>]
#
# Prompts the user to enter Yes or No and returns 0/1.
#
# eg,
#
#    confirm "Would you like to proceed?"  #yes no question

#   if [[ $? == "0" ]]; then  #if yes
#      echo "You answered yes."
#   else
#      echo "You answered no."
#   fi

   local prompt response

   if [ "$1" ]; then prompt="$1"; else prompt="Are you sure?"; fi
   prompt="$prompt [Y/n]"
#  Loop forever until the user enters a valid response (Y/N or Yes/No). Default is yes.
   while true; do
      read -r -p "$prompt " response
      case "$response" in
         [Yy][Ee][Ss]|[Yy]|"") # Yes or Y (case-insensitive) or blank.
         #[Yy][Ee][Ss]|[Yy]) # Uncomment this line and comment out the line ablove to remove default action.
         return 0
      ;;
         [Nn][Oo]|[Nn])  # No or N.
         return 1
      ;;
         *) # Anything else (excluding a blank) is invalid.
      ;;
      esac
   done
}

search() {
#
# syntax: search [<string>] file
#
# Searches a file for a given string returns 0 for true

   local result
   result=$(grep -i "$1" "$2")
   #echo $result
   if [[ -n "$result" ]]; then
      return 0
   else
      return 1
   fi
}

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
# if [[ $? != "0" ]]; then                                                      
#    printf "%s\n" "You need to be root"
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

