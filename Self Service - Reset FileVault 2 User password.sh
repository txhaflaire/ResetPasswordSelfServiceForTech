#!/bin/sh

# Loop until valid input is entered or Cancel is pressed.
while :; do
    userName=$(osascript -e 'Tell application "System Events" to display dialog "Hi, 

Ensure that you have set a new password for the user via Active Directory.

Please now insert the username of the user" default answer "" with title "Requesting Username" with text buttons {"Submit"} with icon caution' -e 'text returned of result' 2>/dev/null)

    if (( $? ));
        then exit 1; fi  # Abort, if technician pressed Cancel.

        userName=$(echo "$userName" | sed 's/^ *//' | sed 's/ *$//')  # Trim leading and trailing whitespace.

    if [[ -z "$userName" ]]; then

        # The technician left the username blank
        osascript -e 'Tell application "System Events" to display alert "You must enter the username. Please try again" as warning' >/dev/null

        # Continue loop to prompt again.

        else
            # Valid input: exit loop and continue.
            break
    fi
done

# Remove user from FileVault 2.
fdesetup remove -user "$userName"
echo "User has been removed from FileVault 2"

sleep 05


# Pass the credentials for the management account that is authorized with FileVault 2
adminName='PUT IN HERE YOUR SUPPORT ACCOUNT'
adminPass="$(osascript -e 'Tell application "System Events" to display dialog "Please enter the password for SUPPORT ACCOUNT" default answer "" with title "Get admin privilliges" with text buttons {"Ok"} default button 1 with hidden answer' -e 'text returned of result')"

# Check if the logged on user is already authorized with FileVault 2
userCheck=`fdesetup list | awk -v usrN="$userName" -F, 'index($0, usrN) {print $1}'`
if [ "${userCheck}" == "${userName}" ]; then
echo "This user is already added to the FileVault 2 list."
osascript -e 'tell app "System Events" to display dialog "This user is already added to the FileVault 2 list." with title "Not able to add user" buttons {"Quit"}'
exit 1
fi

# Check to see if the encryption process is complete
encryptCheck=`fdesetup status`
statusCheck=$(echo "${encryptCheck}" | grep "FileVault is On.")
expectedStatus="FileVault is On."
if [ "${statusCheck}" != "${expectedStatus}" ]; then
echo "The encryption process has not completed, unable to add user at this time."
echo "${encryptCheck}"
osascript -e 'tell app "System Events" to display dialog "The encryption process has not completed, unable to add user at this time." with title "Disk is not encrypted" buttons {"Quit"}'
exit 2
fi

# Get the logged in user's password via prompt
echo "Prompting ${userName} for his/her login password."
userPass="$(osascript -e 'Tell application "System Events" to display dialog "Please enter the password for user '${userName}':" default answer "" with title "Enable user '${userName}' for FileVault 2" with text buttons {"Submit"} default button 1 with hidden answer' -e 'text returned of result')"

echo "Adding user to FileVault 2 list."

# Create the plist file:
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>Username</key>
<string>'$adminName'</string>
<key>Password</key>
<string>'$adminPass'</string>
<key>AdditionalUsers</key>
<array>
    <dict>
        <key>Username</key>
        <string>'$userName'</string>
        <key>Password</key>
        <string>'$userPass'</string>
    </dict>
</array>
</dict>
</plist>' > /tmp/fvenable.plist

# Enable FileVault 2 for the logged on user
fdesetup add -inputplist < /tmp/fvenable.plist

# Check if the user is successfully added to the FileVault 2 list
userCheck=`fdesetup list | awk -v usrN="$userName" -F, 'index($0, usrN) {print $1}'`
if [ "${userCheck}" != "${userName}" ]; then
echo "Failed to add user to FileVault 2 list."
osascript -e 'tell app "System Events" to display dialog "Failed to add user '${userName}' to FileVault 2 list." with title "Filevault 2 Failed" buttons {"Quit"}'
exit 3
fi

echo "${userName} has been added to the FileVault 2 list."
osascript -e 'tell app "System Events" to display dialog "'${userName}' has been added to the FileVault 2 list. Reboot required" with title "Well done, Bro.." buttons {"Hooray"}'

# Clean up
if [[ -e /tmp/fvenable.plist ]]; then
    srm /tmp/fvenable.plist
fi
exit 0

# Updating APFS preboot volume to enable all FV2 users to login
diskutil apfs updatepreboot /

# Restarting macOS
osascript -e 'tell app "loginwindow" to «event aevtrrst»'

exit 0
