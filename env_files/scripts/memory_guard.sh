#!/bin/bash 

# watch for any web tabs that are growing too large
# TODO: find a way to prevent closing of facebook tabs (without warning)

#ps -amcwxo "pid %mem %cpu rss command" | grep -v grep | grep 'com\.apple\.WebKit\.WebContent|Google Chrome Helper'
result=$(ps -amcwxo "pid rss command" | grep -v grep | grep -E 'com\.apple\.WebKit\.WebContent|Google Chrome Helper' | head -n1)
# NOTE: when printed to terminal has a header

#echo $result

mem=$(echo "$result" | awk '{print $2}')
pid=$(echo "$result" | awk '{print $1}')
# find anything in column 2 that is greater than 1000000 and kill it
# ([ $mem -gt 1000000 ] && echo "true") || echo "false"

#echo $mem
#echo $pid
#exit 1

# 1.5GB
if [ $mem -gt 1500000 ]; then
  message='display notification "'$result'" with title "Killed Process"'
  osascript -e "$message"
  kill $pid
fi

# osascript -e 'display notification "Lorem ipsum dolor sit amet" with title "Title"'

# this can run 1 process at a time, as long as we run this often enough
