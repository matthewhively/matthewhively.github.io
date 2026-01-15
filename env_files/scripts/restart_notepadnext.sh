#!/bin/bash 

# Script called by plist file:
#    ~/Library/LaunchAgents/com.matt.notepadnext.plist
#
# Cron-enabled by:  launchctl load   ~/Library/LaunchAgents/com.matt.notepadnext.plist 
# Cron-disabled by: launchctl unload ~/Library/LaunchAgents/com.matt.notepadnext.plist 

# NOTE: the above doesn't work well, because the "permissions" popup still counts as the app running.

echo "Refreshing NotepadNext to save session windows @ $(date)"

# Close the app (gracefully)
osascript -e 'quit app "NotepadNext"'
# NOTE: gives error msg "0:22: execution error: NotepadNext got an error: User canceled. (-128)"

# Apparently using pkill (TERM or QUIT), doesn't seem to do it gracefully (maybe a different signal would work)

sleep 5


# Re-Open the App
open ~/Applications/NotepadNext.app

echo "Completed @ $(date)"
echo
echo