confirm() {
#
# syntax: confirm [<prompt>]
#
# Prompts the user to enter Yes or No and returns 0/1.
#
   local prompt response

   if [ "$1" ]; then prompt="$1"; else prompt="Are you sure?"; fi
   prompt="$prompt [Y/n]"
#  Loop forever until the user enters a valid response (Y/N or Yes/No).
   while true; do
      read -r -p "$prompt " response
      case "$response" in
         [Yy][Ee][Ss]|[Yy]|"") # Yes or Y (case-insensitive) or blank.
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
