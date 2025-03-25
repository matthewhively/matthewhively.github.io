# Types of Shells:
#   1) Interactive & Login
#          opening any terminal window
#          connect via SSH
#   2) Interactive & Non-Login
#          running a shell binary to start a subshell within an already open terminal window
#   3) Non-Interactive & Non-Login
#          automated shell script
#   4) Non-Interactive & Login
#          starting a script's shell with using the --login flag
#          piping output of a command into an SSH connection

# NOTE: bashrc is loaded when: starting an interactive shell that is not a login shell
# NOTE: this file is run once per interactive-shell started
#       therefore it should contain shortcuts, and aliases and functions

############################################
#    COMMON SHORTCUTS                      #
############################################
alias ls='ls -a -G -p -F'
alias ll='ls -a -G -p -F -l'
alias grep='/usr/bin/egrep -n -S --color --exclude-dir=coverage --exclude=*.swp'
# skip the coverage directory when I'm looking for variables/methods/etc
# (-S) follow symlinks when recursive searching
# ... beware, make sure to skip vizmule_cache_fldr/sublime_cache_fldr symlinks once inside shopping_cart_engine dir
#     otherwise you get into an endless loop
# NOTE: all defined functions should use "egrep" directly to avoid complications with this alias

alias ppath='echo $PATH | sed "s/:/\n/g"'
alias senv='env | sort'

# make cd into symlinks change to the ACTUAL directory path
set -o physical

# ignore ctrl+d twice before actually closing the bash session (gives a warning)
export IGNOREEOF=2

# Save shorthand for the gem installation directory
# DO NOT USE "GEM_HOME" as that has some special meaning to some ruby executables
# Lets try GEM_PATH
GEM_PATH() {
  gem env home
}

# IMPORT SECRETS
. ~/.bash_secrets

#echo $MYSQL_VIZ_PROD_PASS

###### Fix pushd popd ########

#cd_pushd()
#{
#  if [ $# -eq 0 ]; then # NOTE: default behavior for cd with no arguments is return home
#    DIR="${HOME}"
#  else
#    DIR="$1"
#  fi
#
#  pushd "${DIR}" > /dev/null
#  echo -n "DIRSTACK: "
#  dirs
#}

#pushd_builtin()
#{
#  builtin pushd > /dev/null
#  echo -n "DIRSTACK: "
#  dirs
#}

#silent_popd()
#{
#  popd > /dev/null
#  echo -n "DIRSTACK: "
#  dirs
#}

# NOTE: does not work, cannot seem to override built in cd command
#alias go='cd_pushd'
#alias back='silent_popd'
#alias back='popd'
#alias flip='pushd_builtin'

############################################
#    customize the terminal prompts        #
############################################

# Add the pwd to the right side
rightprompt() {
    # NOTE: really long paths cause problems
    printf "%*s" $COLUMNS '\w'
}

short_pwd() {
    pwd | awk -F'/' '{print $NF}'
}

terminal_text() {
  echo 'RESET="$(tput sgr0)"' # clear any special formatting in terminal text
  echo 'BOLD="$(tput bold)"'
  echo 'ITALIC="$(tput sitm)"'
  echo 'UNDERLINE="$(tput smul)"'
  echo 'BLINK="$(tput blink)"'
  echo 'DIMMED="$(tput dim)"'
  echo 'GREEN="$(tput setaf 2)"'
  echo 'SILVER="$(tput setaf 8)"'
  echo
  # TODO: fix this printout
  # echo 'print all colors: '
  #printf '\e[48;5;%dm ' {0..255}; printf '\e[0m \n'
}
# Others: from "man terminfo"
#   invis - invisible (can be copy-pasted, but not seen or highlighted)
#   rev   - reverse (not working?)
#   smso  - standout (not working?)
#   sshm  - shadow (not working)
#   ssubm - subscript (not working)
#   ssupm - superscript (not working)

BOLD="$(tput bold)"
SILVER="$(tput setaf 8)"
RESET="$(tput sgr0)"

#export PS1="\[$(tput sc; rightprompt; tput rc)\]\n\[${BOLD}\]bash\[${RESET}\] > "  # NOTE: cannot figure out why the wrap is so strange

# get the name of the currently running program (in this case bash)
# trim "-bash" -> "bash" if necessary # TODO: this is about login/non-login shells isn't it?
SN=${0#-}
SV=$(echo ${BASH_VERSION} | awk -F'(' '{print $1}')

# Set the prompt
export PS1="\[${SILVER}\]\w\[${RESET}\]\n\[${BOLD}\]${SN}(${SV})\[${RESET}\] [\$(short_pwd)]> "

# the directory that contains the viz repos. (some scripts make use of this)
export VIZ_REPO_DIR="${HOME}/vizlabs_repos"

# PORT override for pb_dev_server -- so it doesn't conflict with vizmule dev
#export PB_PORT="3030"
export PB_PASS="NONE"



# https://apple.stackexchange.com/a/370287
set_tab_name()
{
  if [ -n "$1" ]; then
    echo -en "\033]1; ${1} \007"
    export TAB_NAME=$1
  else
    echo "Choose a name for this tab"
  fi
}

# Because ssh-ing to another host changes the tab's name, we need to reset it to my custom tab-name afterward.
ssh() {
  /usr/bin/ssh "$@"
  set_tab_name $TAB_NAME
}

############################################
#    General Helpers                       #
############################################

# NOTE: methods that should not be listed in rem() should have { on the same line as the method name

# helper in case I forget what exists, should just list all the functions
rem() {
    egrep '^[a-zA-Z_]+\(\)$' ~/.bashrc
    echo
    echo "Ruby Gem Dir: $(GEM_PATH)" # NOTE: workaround to prevent apple session saving for subshells
    echo "crontab -e is written here /var/spool/cron/"
    echo "print definition of a shell function using 'declare -f <function_name>'"
}

# This utility is not installed on macos, but is on our linux machines
alias sensible-pager='less'

# override "man" command so it will work with built-ins as well
man() {
    case "$(type -t -- "$1")" in
    builtin|keyword)
        help -m "$1" | sensible-pager
        ;;
    *)
        command man "$@"
        ;;
    esac
}

# https://www.folkstalk.com/2013/03/sed-remove-lines-file-unix-examples.html
clean_known_hosts()
{
  [ -z "$1" ] && echo "USAGE: clean_known_hosts <line_number>" && return 1

  # verify $1 is a positive number
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    sed -i'.bak' "${1}d" ~/.ssh/known_hosts
    rm ~/.ssh/known_hosts.bak  # cleanup the extra backup
    echo "Successfully removed line number $1 from known_hosts file"
  else
    echo "USAGE: clean_known_hosts <line_number>" && return 1
  fi
}

free()
{
   python ~/scripts/free_mem.py
}

symlink()
{
  # TODO: can I make dest/source interchangable in a safe way?
  [ -z "$2" ] && echo "USAGE: symlink <source> <dest>" && return 1

  # TODO: allow force?
  ln -s $(realpath $1) $2
}

# for bummr
# compares current (empty) branch to this parent branch
# for some reason this is required
# NOTE: not every repo that can make use of bummr has a "dev" branch (example insights)
export BASE_BRANCH='dev'

############################################
#    REMOTE SCRIPT STORAGE                 #
############################################

# Moves the HEAD of the 'deploy' branch to the latest revision of the specified branch
git_pin() {
   branch=$1
   if [ -z "$branch" ]; then
     echo "USAGE: ${FUNCNAME[0]} 'BRANCH_NAME'"
   else
  
     git fetch --all
     git checkout $branch
     git pull
     # TODO: what if there are conflicts?
     [ $? -eq 1 ] && echo "Cannot continue, pull failed (conflicts?)" && return 1

     revision=$(git branch -v | egrep 'mh/new_digital_product' | awk '{print $2}')
     git branch -f deploy $revision
     git checkout deploy
     echo
     echo "Don't forget to restart unicorn!"
   fi
}

# NOTE: only use on PB2 server, not for personal laptops -- this could be a script instead?
restart_unicorn() {
   systemctl stop unicorn
   echo 'stopped...'
   sleep 1
   systemctl start unicorn
   echo 'started...'
   sleep 2
   systemctl status unicorn
}

# alt version for AWS instances
restart_unicorn() {
   # TODO: make this generic for sublime and vizmule  (insights doesn't matter, but is a bonus)
   pushd /srv/vizmule_rails/railsapp

   # TODO: maybe instead do 1 step of restart/reload unicorn? 
   # from railsapp/bin/stop_unicorn.sh
   bundle exec /etc/init.d/unicorn stop /etc/unicorn/vizmule.conf
   echo 'stopped...'
   sleep 1
   # from railsapp/bin/start_unicorn.sh
   bundle exec /etc/init.d/unicorn start /etc/unicorn/vizmule.conf
   echo 'started...'
   sleep 2
   ps -ejf | grep 'unicorn'

   popd
}

staging_admin_on() {
  pushd /srv/vizmule_rails/railsapp/config/settings
  # key: allow_access_to_admin_site
  sed -i'.bak' -E 's/admin_site: false/admin_site: true/' staging.yml

  restart_unicorn
  popd
}

############################################
#    MySQL helpers                         #
############################################

# NOTE: to see mysqld version (while logged in through the client)
#       SHOW VARIABLES LIKE 'version';

# args: 1=container_name(optional)
# TODO: allow optional additional environment vars to be declared/passed
# TODO: allow choice of image_tag
docker_run_mysql()
{
  container_name="mysql-docker-container"
  [ -n "$1" ] && container_name=$1

  docker inspect "$container_name" &> /dev/null
  # If container exists...
  if [ $? -eq 0 ]; then
    # ... is it running?
    docker inspect -f '{{.State.Status}}' "$container_name" | grep -q "running"
    [ $? -eq 0 ] && >&2 echo "ABORT: The container '$container_name' is running. Stop it with 'docker stop $container_name'" && return 1
  fi

  image_tag="latest"

  dockerlogin "quiet"

  # Clean up the old (stopped) container
  docker rm $container_name &> /dev/null

  docker_image="807374381268.dkr.ecr.us-east-1.amazonaws.com/viz-mysql8-test-data:${image_tag}"

  # pull the latest version of this image
  docker pull $docker_image

  # TODO: clean up old images (save disk space)

  # Run the new container
  docker run -d -p 3306:3306 \
             -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -e MYSQL_ROOT_HOST='%' -e MYSQL_USER=viz -e MYSQL_PASSWORD=password \
             --name $container_name $docker_image > /dev/null
  if [ $? -eq 0 ]; then
    echo -e "\nSUCCESS: docker container '$container_name' has been started"
  else
    >&2 echo -e "\nERROR: docker container '$container_name' failed to start"
  fi
}

#brew services stop mysql
#brew services start mysql

mysql_use_83()
{
  brew unlink mysql@8.0
  brew link mysql@8.3
  brew services restart mysql
  echo
  mysql --version
}

mysql_use_80()
{
  brew unlink mysql@8.3
  brew link mysql@8.0
  brew services restart mysql
  echo
  mysql --version
}

# Helper for determining local mysql table size.
# TODO: this can easily be modified to work on any of RDS DBs in AWS cloud
mysql_db_size()
{
  DB_NAME=$1
  echo '
SELECT
ROUND(((data_length + index_length) / 1024 / 1024), 2) AS `Size (MB)`,
table_name AS "Table" FROM information_schema.TABLES
WHERE table_schema = "'$DB_NAME'" having `Size (MB)` > 1
ORDER BY (data_length + index_length) DESC;' | mysql -u root
}

# NOTE: if using mysqldump local machine is version 8, and remote is version 5.X  so make sure to use "--column-statistics=0" to avoid some errors

add_test_users()
{
  # only works for test db, not production
  if [ "$1" != 'test' -a "$1" != 'pre' -a "$1" != 'staging' -a "$1" != 'approvals' ]; then
    echo "Choose which db: test OR pre OR staging OR approvals"
    return 1
  fi

  fn="create_test_users.sql"
  site="viz"
  if [ "$2" == 'yaoi' ]; then
    site='yaoi'
    fn='sublime_test_users.sql'
    # technically only test/staging work for sublime but we can ignore that for now
  fi
  cat ${VIZ_REPO_DIR}/labs_dev/docs/$fn | mysql -h $LABS_CLUSTER_HOST -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS} "${site}$1"
}

# KINDA DEFUNCT: for reference only
make_site_page_dump()
{
  if [ -z "$1" ]; then
    echo "choose a site_page_id"
    return 1
  fi

  site_page_id=$1
  promo_zone_id=$(echo "SELECT promo_zone_id FROM site_pages WHERE id = ${site_page_id}" | mysql -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 | tail -n1)

  if [ -z "$promo_zone_id" ]; then
    echo "ERROR: promo_zone not found"
    return 1
  fi

  site_page_layout_id=$(echo "SELECT id FROM site_page_layouts WHERE site_page_id = ${site_page_id}" | mysql -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 | tail -n1)

  if [ -z "$site_page_layout_id" ]; then
    echo "ERROR: layout not found"
    return 1
  fi

  #echo "site_page: ${site_page_id} | layout: ${site_page_layout_id} | promo_zone: ${promo_zone_id}"

  # TODO: figure out how to silence "Warning: Using a password on the command line interface can be insecure."

  # get the promo_zone
  mysqldump -t --compact -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 promo_zones --where="id = ${promo_zone_id}"

  # get the promo_zone_images
  mysqldump -t --compact -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 promo_images --where="promo_zone_id = ${promo_zone_id}"

  # get the site_page for that promo_zone
  mysqldump -t --compact -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 site_pages --where="id = ${site_page_id}"

  # get the site_page_layout
  mysqldump -t --compact -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 site_page_layouts --where="id = ${site_page_layout_id}"

  # get the site_page_layout_sections
  mysqldump -t --compact -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2 site_page_layout_sections --where="site_page_layout_id = ${site_page_layout_id}"
}

############################################
#    MySQL connection shortcuts            #
############################################

# ??? what was this needed for ???
# --ssl-mode=disabled
# why not?
# --ssl-mode=prefer

# TODO: more configs found in ~/.my.cnf

con_prod_db()
{
  mysql -A -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2
}

con_prod_yaoi_db()
{
  mysql -A -h $PROD_CLUSTER_HOST -u ${MYSQL_YAOI_PROD_USER} -p${MYSQL_YAOI_PROD_PASS} yaoi
}

# NOTE: writable DB only
con_insights_db()
{
  mysql -A -h $PROD_CLUSTER_HOST -u ${MYSQL_INSIGHT_PROD_USER} -p${MYSQL_INSIGHT_PROD_PASS} insight
}

# for test/pre/staging etc
# TODO: from dev machine only works with direct IP address (see etc/hosts)
con_test_db()
{
  #echo "permissions issue! Connect from EC2 instance"
  #echo "mysql -h ${LABS_CLUSTER_HOST} -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}"
  mysql -A -h $LABS_CLUSTER_HOST -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}

  #mysql -h 172.30.1.139 -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}
}

# REM: the AWS version
con_pb_db()
{
  mysql -A -h $PROD_CLUSTER_HOST -u ${MYSQL_PB_USER} -p${MYSQL_PB_PASS} productbible
}

rds_replica_status()
{
  # TODO: make an AWS query to retrieve the RDS hosts that exist.
  #       list them (1,2,3...) and choose which one.
  host=$1
  [ -z "$host" ] && echo "choose a host DB" && return 1
  echo "show replica status\G" | mysql -A -h $host -u ${MYSQL_PROD_ROOT_USER} -p${MYSQL_PROD_ROOT_PASS} viz2 | grep 'Replica_|Seconds_'
}

############################################
#    Navigation Shortcuts                  #
############################################

chef()
{
cd ${VIZ_REPO_DIR}/chef-aws/VIZAWSOW/files/default/viz_rails_config/
}

# TODO: allow vizmule_rails_alt
vizmule()
{
cd ${VIZ_REPO_DIR}/vizmule_rails/railsapp
}

sublime()
{
cd ${VIZ_REPO_DIR}/sublime/railsapp
}

############################################
#    Git Helpers                           #
############################################

alias vdgd="git difftool --tool=vimdiff --no-prompt"
alias vdgds="git difftool --tool=vimdiff --no-prompt --staged"

# easily start a bisect in 1 command
git_bisect()
{
  # NOTE: not easy to run this in reverse
  #       we have to "pretend" that the fixed thing is actually newly broken
  if [ -z "$1" ]; then
    echo "Usage: ${FUNCNAME[0]} 'last_known_good_revision_hash'"
    echo
    echo "continue with: 'git bisect good/bad/skip'"
    echo "end with: 'git bisect reset'"
  else

    revision=$1

    git_root=$(git rev-parse --show-toplevel)
    cd $git_root

    git bisect start
    git bisect bad              # Current version is bad
    git bisect good $revision   # known good revision
  fi
}

# fully revert to the last commit for this branch, all local changes, staged and untracked files removed
git_revert()
{
   echo -e "git reset\ngit checkout .\ngit clean -f"
   # TODO: is there any way to force this to be in the "root" of the git repo?
   git reset
   git checkout .
   git clean -f
}

git_prune()
{
  git remote prune origin
}

gf()
{
  # TODO: abort if current folder isn't part of a git repo
  git fetch --all
  # may as well prune at the same time
  git remote prune origin
}

git_fp()
{
  git push origin $1 -f
}

# spp = stash, pull, pop
# for when there are local changes that prevent a pull
git_spp()
{
  git stash save spp
  git pull
  git stash pop
}

# TODO: add a way to choose an alternative merging strategy as an initial arg (not a read param) (use flag -s)
git_rebase()
{
  # git rebase --onto <place-to-put-it> <last-change-that-should-NOT-move> <(branch_name OR change_hash) to move>
  # if last-change-that-should-NOT-move is skipped, will use last-common-ancestor
  # if target_name is skipped, will use current branch, or HEAD

  echo -n "${BOLD}Destination Commit:${RESET} "
  read destination_commit

  if [ -z "$destination_commit" ]; then
    echo "A Destination commit must be chosen. ABORT"
    return 1
  fi

  echo -n "${BOLD}Branch/Commit to move (default current):${RESET} "
  read target_name

  if [ -z "$target_name" ]; then
    target_name=$(git branch --show-current)
    # if it is still empty, use HEAD
    [ -z "$target_name" ] && target_name="HEAD"
  fi

  echo -n "${BOLD}Last change that should not move (default last_common_ancestor):${RESET} "
  read last_change_that_should_not_move

  # NOTE: as far as I know, this cannot fail
  if [ -z "$last_change_that_should_not_move" ]; then
    last_change_that_should_not_move=$(git merge-base $destination_commit $target_name)
  fi

  #echo "git rebase --onto ${destination_commit} ${last_change_that_should_not_move} ${target_name}"
  git rebase --onto ${destination_commit} ${last_change_that_should_not_move} ${target_name}
}

# TODO: add a helper to manage cherry-picking within an ongoing rebase (in case of errors)
# https://stackoverflow.com/a/68948140

git_manual_diff()
{
  # WARN: does not work properly during a git_rebase... BEWARE (TODO: detect and alert)
  path=$1
  REPO_ROOT=$(git rev-parse --show-toplevel) # example: /Users/matthewhively/vizlabs_repos/vizmule_rails

  if [ -z "$path" ]; then
    echo "USAGE: git_manual_diff [file_path]"
  elif [ -z "$REPO_ROOT" ]; then
    echo 'ERROR: Current working directory is not part of a GIT repo! Cannot continue'
  else
    filename=$(basename $path) # just the file itself
    rm -f /tmp/*.${filename}   # clear out any old copies

    filepath=$(realpath $path) # get the FULL path of the file (no shortcuts, symlinks etc)
    rel_file_path=${filepath#$REPO_ROOT/} # remove substring ${string#substring}

    git show :1:${rel_file_path} > /tmp/common.${filename} # common ancestor
    git show :2:${rel_file_path} > /tmp/ours.${filename}
    git show :3:${rel_file_path} > /tmp/theirs.${filename}

    echo "/tmp/common.${filename}"
    echo "/tmp/ours.${filename}"
    echo "/tmp/theirs.${filename}"
    echo "manual merge:"
    echo "   vimdiff /tmp/theirs.${filename} /tmp/ours.${filename}"
  fi
}

alias gmd=git_manual_diff
# TODO: print this alias as part of REM()

diff_sublime_to_vizmule()
{
  path=$1
  # TODO: allow outside of railsapp dir
  pwd | egrep 'sublime/railsapp' > /dev/null
  is_sublime=$?
  if [ -z "$path" ]; then
    echo "USAGE: diff_sublime_to_vizmule [file_path] <alt (vizmule)>" && return 1
  elif [ $is_sublime -eq 1 ]; then
    echo "Must be run from in the sublime/railsapp directory" && return 1
  fi

  vizmule_dir='vizmule_rails'
  if [ "$2" == 'alt' ]; then
    vizmule_dir='vizmule_rails_alt'
  fi

  echo "diffing ... $path $VIZ_REPO_DIR/$vizmule_dir/railsapp/$path"
  sleep 2
  # TODO: create a way to properly compare files that were upgraded to erb templates, like .js.erb 
  vimdiff $path $VIZ_REPO_DIR/$vizmule_dir/railsapp/$path
}

# Not as easy to use as it could be, but it mostly works
git_blame()
{
  # modes for specifying line numbers
  #   120 => just line 120
  #   120,200 is from line 120 up to line 200
  #   120+5   is from line 120 up to line 125
  #   120-5   is from line 115 up to line 120
  #   120~5   is from line 115 up to line 125
  # FUTURE-TODO: add an easy way to backtrace to get around silly changes (like spacing etc)
  read -r -d '' USAGE <<'EOF'
USAGE: git_blame <file>[:line_num[<sep>num]] [revision_to_ignore [...]]
       where <sep> can be:
         , => from,to_x
         + => from,from+x
         - => from-x,from
         ~ => from-x,from+
EOF

  if [ -z "$1" ]; then
    echo "$USAGE" && return 1
  fi

  tmp=$1
  shift # we already processed the first arg

  # -----------
  # WARNING: Use with caution
  #          ignore-revs is not exactly safe/trustworthy
  #          the targeted line will always be shown exactly as it currently is, but with its blame re-assigned to a change BEFORE the ignored commit
  #          therefore only skip over syntactically irrelevant commits

  # NOTE: cannot use "git blame <commit-hash> -- <file>" because then the line number is mutated and its impossible to automatically locate your target code
  # <commit-hash>~1 or <commit-hash>^ to go one revision before

  # Loop through each argument and prefix it
  ignore_revs=()
  for rev in "$@"; do
    ignore_revs+=("--ignore-rev $rev")
  done
  ignore_revs_str="${ignore_revs[@]}" # convert it to a string
  #echo "testing ignore_revs: '${ignore_revs}'"

  # -----------

  # TODO: if target line is greater than the last line of the file, both log and blame commands throw an error

  arr=(${tmp//':'/ }) # split by ":"
  FILE=${arr[0]}
  tmp=${arr[1]}
  # if we have at least a line_num supplied
  if [ -n "$tmp" ]; then
    # find the first non number character ... maybe empty
    SPLITTER=$(echo "$tmp" | egrep -o '[^0-9]' | head -n 1)
    [ -z "$SPLITTER" ] && SPLITTER=',' # FAILSAFE
    # if not an accepted splitter value, show USAGE and exit
    echo "$SPLITTER" | egrep -q '[,~+\-]' 
    if [ $? -ne 0 ]; then
      echo "$USAGE" && return 1
    fi

    arr=(${tmp//$SPLITTER/ })
    # WARN: If user puts some other garbage character inbetween the numbers, its ok, just blow up
    line_num=${arr[0]}
    tmp=${arr[1]}
    # if we have an additional number after the line_num
    if [ -z "$tmp" ]; then
      # show just this line
      other_num=1
      opp='+'
      # also valid line_num,line_num
    else
      other_num=$tmp
      opp=$SPLITTER
    fi

    # Set the args based on the opperation
    if   [ ',' == $opp ]; then
      args="-L ${line_num},${other_num}"
  
    elif [ '+' == $opp ]; then
      args="-L ${line_num},+${other_num}"
  
    elif [ '-' == $opp ]; then
      args="-L ${line_num},-${other_num}"
  
    elif [ '~' == $opp ]; then
      # TODO:
      let "start_line = line_num - other_num"
      let "end_line   = line_num + other_num"
      # enforce min of 0 (max doesn't matter)
      [ $start_line -lt 0 ] && start_line=0
  
      args="-L ${start_line},${end_line}"
    fi

    # Print the full commit message for the most recent (non-ignored) commit of the target line
    # this should give us more clues whether we want to use --ignore-rev on that commit_hash
    echo "git log --no-patch -n 1 -L ${line_num},+1:${FILE} --skip=${#ignore_revs[@]}"
    # NOTE: Assumption, each ignored revision is directly from the target line.
    git log --no-patch -n 1 -L ${line_num},+1:${FILE} --skip=${#ignore_revs[@]}
    # TODO: for some reason this just stops printing output sometimes... even though there are clearly more changes
    echo '-----------------------------'
  fi

  # NOTE: specify HEAD so we ignore any as of yet uncommitted changes
  echo "git blame $ignore_revs_str $args HEAD -- $FILE"
  git blame $ignore_revs_str $args HEAD -- $FILE

}


############################################
#    Dev Shortcuts                         #
############################################

# https://rossta.net/blog/local-ssl-for-rails-5.html
makecrt()
{
name="dev.viz.com"
openssl req \
  -new \
  -newkey rsa:2048 \
  -sha256 \
  -days 3650 \
  -nodes \
  -x509 \
  -keyout $name.key \
  -out $name.crt \
  -config <(cat <<-EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  CN = $name
  [v3_req]
  keyUsage = keyEncipherment, dataEncipherment
  extendedKeyUsage = serverAuth
EOF
)
}

build_cart()
{
  if [ ! -f shopping_cart_engine.gemspec ]; then
    echo "Must be run from shopping_cart_engine folder."
    return 1
  fi

  # print current version number
  echo "Current version: $(egrep 'VERSION' lib/shopping_cart_engine/version.rb | awk '{ print $3 }')"
  # read input for new version number (default unchanged)
  echo -n "${BOLD}New Version Number (optional):${RESET} "
  read version_number

  # maybe update version number
  # TODO: enforce parsing of the version number?
  if [ -n "$version_number" ]; then
    # Replace the entire file. I couldn't get SED to work properly
    printf "module ShoppingCartEngine\n  VERSION = \"${version_number}\"\nend\n" > lib/shopping_cart_engine/version.rb

    # commit the version update...
    git commit lib/shopping_cart_engine/version.rb -m "Version bump to ${version_number}"
    # ...But don't push

    # tag the commit with the version number
    git tag "${version_number}"
  fi
  # NOTE: does not commit changes

  # build the gem
  gem build shopping_cart_engine.gemspec
}

# Get the temporary (12hr) login session approved.
# NOTE: this is only for docker containers, not for aws as a whole
#       for other aws commands simply attach --profile MYPROFILE to the aws command
# example: aws --profile produser s3 ls s3://viz-manga/manga/shonenjump/wsja/ --exclude "*" --include "<your_regex>"

# $1 == quiet flag
dockerlogin()
{
  $VIZ_REPO_DIR/viz-mysql-data/script_blocks/docker_login.sh $1
  return $?
}

# fix the time sync in docker environment
#docker_timefix()
#{
#    sudo ntpdate -u time.apple.com  # fix my OWN computer's local time (cause it gets fucked up somehow)
#    docker run --rm --privileged alpine hwclock -s
#}
#docker_timecheck()
#{
#    echo -n "docker: " && docker run --rm alpine date -u
#    echo -n "system: " && date -u
#}

#docker_artifacts()
#{
#    ${VIZ_REPO_DIR}/labs_dev/docs/docker_log_copy.sh
#}

#docker_reload()
#{
#    ${VIZ_REPO_DIR}/labs_dev/docs/reload_docker_rails.sh $1
#}

#docker_test_reset()
#{
#    cat ${VIZ_REPO_DIR}/labs_dev/docs/viztest_reset.sql | docker-compose run vizmule mysql -h mysql_host -u root viztest
#    # ALSO need to purge the entitlement cache somehow --- this may result in broken links?
#    #docker-compose stop redis   # stop it
#    #docker-compose rm redis     # remove it
#    #docker-compose up -d redis  # re-create/start it
#    #docker run --link redis:redis --rm redis redis-cli -h redis -p 6379 FLUSHALL # ??? this did work
#    echo ''
#    docker run --rm redis redis-cli -h redis -p 6379 FLUSHALL
#
#    # now clear the log files etc
#    docker-compose run vizmule /bin/bash  -c "rm -rf /srv/vizmule_rails/railsapp/docker_data/*; truncate -s0 /srv/vizmule_rails/railsapp/log/*.log"
#}

#docker_tail()
#{
#    NEW=$(docker-compose ps | egrep 'vizmule_(dev_)?container.*Up' | head -n1 | awk '{print $1}')
#    docker exec -i -t  $NEW  tail -n0 -q -f  log/development.log  log/test.log
#}

sync_env_files()
{
  # WIP
  cp ~/.bash_profile ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.bashrc       ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.gemrc        ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.gitconfig    ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.inputrc      ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.irbrc        ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.vimrc        ~/misc_repos/matthewhively.github.io/env_files/.

  # TODO: sync some of .vim, but not all of it
  #cp -a ~/.vim    ~/misc_repos/matthewhively.github.io/env_files/.

  cp -a ~/scripts  ~/misc_repos/matthewhively.github.io/env_files/.
}

# start rails with its network binding setup so that I can load it locally on a mobile device
rails_bind()
{
  #ip=$(ifconfig en3 | egrep "inet " | egrep -Fv 127.0.0.1 | awk '{print $2}') #WIRED connection
  ip=$(ifconfig | egrep "inet " | tail -n1 | awk '{print $2}') # get the last one, we assume the order is LO, WiFi, Wire
  # TODO: list the correct port for pb server 3030
  echo "mobile device connect to: '${ip}:3000'"
  echo
  # NOTE: $@ expands to all arguments
  rails s -b 0.0.0.0 "$@"
}

#rails_redshift_console()
#{
#  # TODO: fix to automatically shift into vizmule project folder
#  REDSHIFT_REMOTE='true' REDSHIFT_DB='production' REDSHIFT_USER=${DW_REDSHIFT_USER} REDSHIFT_PASSWORD=${DW_REDSHIFT_PASSWORD} rails c
#}

# Set the default text editor
export EDITOR=vim

# Firebase/Firestore credentials via "Google Application Default Credentials"
#export GOOGLE_APPLICATION_CREDENTIALS="${VIZ_REPO_DIR}/vizmule_rails/railsapp/config/vizmule-9dca1dab322d.json"

# Maybe enable export of VIZ_RESQUE_BOT_TOKEN if needed (see bash_secrets)

# Turn on test environment debug logging
#USE_STDOUT_LOG=true
# :debug, :info, :warn, :error, :fatal, :unknown
#RAILS_LOG_LEVEL='debug'

# TODO: make shortcut methods to set/unset these
# export RAILS_MYSQL_DEBUG=1    # to turn on MySQL level debug logging

# export EXTRA_SECTION_DEBUG=true  # enhance the debug logging in the section helper

# Bump up the default latest activity timer internal from 1min => 24hrs
export RAILS_LATEST_ACTIVITY_INTERVAL=86400

############################################
#    ssh shortcuts for AWS                 #
############################################

# "aws ssm start-session" requires:
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# TODO: do we need to reset the tab name after these connections too?
#       set_tab_name $TAB_NAME

# Connect directly via instance_id
# automatically tries both vizlabs and vizprod before giving up
# NOTE: its not clear whether both prod/labs accounts could have an instance with
#       the same ID concurrently, but it seems so rare as to be ignorable
con_ssm_ectwo()
{
  if [ -z "$1" ]; then
    echo "USAGE: con_ssm_ectwo <instance-id>"
    return 1
  fi
  INSTANCE_ID=$1

  # NOTE: instance MUST be managed through ssm for this to work
  # REM: always throw out default obtuse error messaging

  aws ssm start-session --profile vizprod --target "${INSTANCE_ID}" 2>/dev/null
  RES1=$?

  # Retry for vizlabs
  if [ $RES1 -ne 0 ]; then
    aws ssm start-session --profile vizlabs --target "${INSTANCE_ID}" 2>/dev/null
    RES2=$?

    if [ $RES2 -ne 0 ]; then
      echo "ERROR: Cannot connect to instance: '${INSTANCE_ID}'. VizLabs(${RES1}) nor VizProd(${RES2})"
      return 1
    fi
  fi
}

# New version of the ectwo connection helper function
# REM: Relies on properly configured AWS profiles in your home folder
con_ssm_app_layer()
{
  if [ -z "$2" ]; then
    echo "USAGE: con_ssm_ectwo <APP Vizmule/Sublime/Insights/Pb> <LAYER>"
    echo "Recognized layers:"
    echo "  Group1/Group2/Admin/Bg/Test/Pre/Pre1/Approvals"
    echo "  + Prod => Group1 & Group2"
    # NOTE: for insights, just type any layer
    return 1
  fi

  APP_NAME=$1
  LAYER_NAME=$2
  # Capitalize the first letter of each var.
  # NOTE: if you use ALL CAPS it will not correct that
  APP_NAME=${APP_NAME^}
  LAYER_NAME=${LAYER_NAME^}
  #echo "${APP_NAME^} - ${LAYER_NAME^}"

  # 0) validate app name
  if [[ ! " Sublime Vizmule Insights Pb " =~ " ${APP_NAME} " ]]; then
    echo "urecognized app. Got '${APP_NAME}'. ABORT"
    return 1
  fi

  # 1) intelligently choose which AWS account to query
  if [ 'Insights' == "${APP_NAME}" ]; then
    PROFILE='vizprod'
    # Layer is irrelevant for insights -- 2023-10-16

  elif [ 'Prod' == "${LAYER_NAME}" ]; then
    PROFILE='vizprod'
    LAYER_NAME='Group1,Group2'

  elif [[ " Group1 Group2 Admin Bg " =~ " ${LAYER_NAME} " ]]; then
    PROFILE='vizprod'

  elif [[ " Test Pre Pre1 Approvals Staging " =~ " ${LAYER_NAME} " ]]; then
    PROFILE='vizlabs'

  else
    echo "unrecognized layer. Got '${LAYER_NAME}'. ABORT"
    return 1
  fi

  FILTERS="Name=instance-state-name,Values=running Name=tag:ApplicationName,Values=${APP_NAME}"
  if [ 'Insights' != "${APP_NAME}" ]; then
    # NOTE: insights only has a single layer. For all other apps also include a layer filter
    FILTERS="${FILTERS} Name=tag:LayerName,Values=${LAYER_NAME}"
  fi

  # DEBUGGING:
  #echo $FILTERS
  #echo aws ec2 describe-instances --profile $PROFILE --filters $FILTERS --query "Reservations[].Instances[].InstanceId" --output text
  #return 1

  # 2) get the first running instance-id
  INSTANCE_ID=$(aws ec2 describe-instances --profile $PROFILE --filters $FILTERS --query "Reservations[].Instances[].InstanceId" --output text | awk '{print $1}')

  # if empty, print an error
  if [ -z "${INSTANCE_ID}" ]; then
    echo "All instances for app ${APP_NAME} in layer ${LAYER_NAME} are not ready for connections (maybe offline?)"
    return 1
    # Maybe useful Query:
    # aws ec2 describe-instances --profile $PROFILE --filters Name=tag-key,Values=opsworks:instance --query "Reservations[].Instances[].{Name: Tags[?Key=='Name'].Value | [0], Id: InstanceId, State: State.Name}" --output table
  fi

  # DEBUGGING:
  #echo "Found instance id: ${INSTANCE_ID}"
  #return 1

  # 3) connect to the instance
  # NOTE: we could use con_ssm_ectwo, but lets not complicated things further
  aws ssm start-session --profile $PROFILE --target "${INSTANCE_ID}"
}

# Just as a reminder
con_insights_internal()
{ 
  ssh insightsinternal
}

##############################

# auto discovered local network servers
# pb
# dp
# labuntu  -- new up-to-date server for the future of digital_publishing
# webstage
# ...

##############################

# EXPERIMENTAL chruby   (which also uses the .rvm folder... anoyingly)
# TODO: looks like ruby-install puts stuff into a .rubies folder... instead of .rvm... so wehre did I get the above from???
# prep (if using RVM):
: '
    mv ~/.rvm ~/.silenced-rvm; mv ~/.chruby-rvm ~/.rvm
    mkdir -p ~/.rvm
    cp -a ~/.silenced-rvm/rubies ~/.rvm/.
'

# QUESTION: can we copy over installed ruby binaries from ~/.rbenv/versions/ ?

# comment out any rvm/rbenv sourcing from bash_profile

# add to bash_profile
: '
source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh
RUBIES+=(~/.rvm/rubies/*)
# Automatically change version when switching folders
source $(brew --prefix)/opt/chruby/share/chruby/auto.sh
'

# REM: manually change version with:
# chruby ruby-2.7.8

# restore (if using RVM):
: '
    mv ~/.rvm ~/.chruby-rvm
    mv ~/.silenced-rvm ~/.rvm
'
# fix your bash_profile to remove chruby again

