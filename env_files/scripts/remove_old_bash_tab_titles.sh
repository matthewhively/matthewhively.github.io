#!/usr/bin/env bash

# See .bashrc
tabtitle_dir="$HOME/.cache/tabtitles"
# MacOS maintains tab history files here, so its maintained to the current list of alive bash tabs
bash_sessions_dir="$HOME/.bash_sessions"

[[ -d "$tabtitle_dir" ]]      || exit 0
[[ -d "$bash_sessions_dir" ]] || exit 0

find "$tabtitle_dir" -type f ! -name '.*' | while read -r file; do
  session_id="$(basename "$file")"

  if ! ls "$bash_sessions_dir/${session_id}"* >/dev/null 2>&1; then
    rm -f "$file"
  fi
done

# ref: https://chatgpt.com/share/e/6a0cd6e4-7854-800b-a939-ff2edb9d5da9
