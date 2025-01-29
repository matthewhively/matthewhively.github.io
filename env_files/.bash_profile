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

# is interactive
if [ -n "$PS1" ]; then
  # file exists
  if [ -f ~/.bashrc ]; then
      # Force load bashrc so that all interactive shells have the same commands defined
      source ~/.bashrc
  fi
fi

