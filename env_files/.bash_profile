# REM: .bash_profile is executed for any "login" shells (E.G. cmd "bash -l" or opening a new terminal window)
# NOTE: bash reads (in order) ~/.bash_profile, ~/.bash_login, ~/.profile  and executes only the first one it finds

# QUESTION: what sort of commands should go here instead of bashrc?

# Setup homebrew path and env_vars
eval "$(/opt/homebrew/bin/brew shellenv)"
# Disable homebrew auto-updating of all installed kegs
export HOMEBREW_NO_AUTO_UPDATE=1

# Configure rbenv (path, env_vars + rbenv() fn)
eval "$(rbenv init -)"

# the directory that contains the viz repos. Just in case scripts need to know
# TODO: move VIZ_REPO_DIR here?

# is an interactive shell
is_interactive=0
[ -n "$PS1" ] && is_interactive=1

# ----------------

# Adjust path -- QUESTION: should this move into .bash_profile ?

# Custom bin directory so I don't have to use sudo to add things to /usr/local/bin
export PATH="$PATH:/Users/matthewhively/bin"

# REM: yarn should be at the front of the path (TODO: move it there if necessary)
YARN_PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"

# Check if the directory is already in the PATH
if [[ ":$PATH:" != *":$YARN_PATH:"* ]]; then
    # Add the directory to the PATH
    export PATH="$YARN_PATH:$PATH"
    [ $is_interactive -eq 1 ] && echo "Added '$YARN_PATH' to the PATH."
#else
#    [ $is_interactive -eq 1 ] && echo "$YARN_PATH is already in the PATH."
fi

# ----------------

if [ $is_interactive -eq 1 ]; then
  # file exists
  if [ -f ~/.bashrc ]; then
      # Force load bashrc so that all interactive shells have the same commands defined
      source ~/.bashrc
  fi
fi

