############################################
#    COMMON SHORTCUTS                      #
############################################
alias ls='ls -a -G -p -F'
alias ll='ls -a -G -p -F -l'
alias grep='/usr/bin/egrep -n -S --color --exclude-dir=coverage --exclude-dir=vizmule_cache_fldr --exclude-dir=sublime_cache_fldr --exclude=*.swp'
# skip the coverage directory when I'm looking for variables/methods/etc
# skip the vizmule_cache_fldr symlink from inside shopping_cart
# follow symlinks when recursive searching
# NOTE: all defined functions should use "egrep" directly to avoid complications with this alias

# make cd into symlinks change to the ACTUAL directory path
set -o physical

# ignore ctrl+d twice before actually closing the bash session (gives a warning)
export IGNOREEOF=2

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
rightprompt()
{
    # NOTE: really long paths cause problems
    printf "%*s" $COLUMNS '\w'
}

short_pwd()
{
    pwd | awk -F'/' '{print $NF}'
}

BOLD="$(tput bold)"

#ITALIC="\[$(tput sitm)\]"      # NOTE DOES NOT WORK
#ITALIC_OFF="\[$(tput ritm)\]"

# NOTE: print all colors    printf '\e[48;5;%dm ' {0..255}; printf '\e[0m \n'
GREEN="$(tput setaf 2)"
SILVER="$(tput setaf 8)"
RESET="$(tput sgr0)"

#export PS1="\[$(tput sc; rightprompt; tput rc)\]\n\[${BOLD}\]bash\[${RESET}\] > "  # NOTE: cannot figure out why the wrap is so strange

# get the name of the currently running program (in this case bash)
# trim "-bash" -> "bash" if necessary
SN=${0#-}
SV=$(echo ${BASH_VERSION} | awk -F'(' '{print $1}')

# Set the prompt
export PS1="\[${SILVER}\]\w\[${RESET}\]\n\[${BOLD}\]${SN}(${SV})\[${RESET}\] [\$(short_pwd)]> "

#the directory that contains the viz repos. Just in case scripts need to know
export VIZ_REPO_DIR="${HOME}/vizlabs_repos"

# PORT override for pb_dev_server -- so it doesn't conflict with vizmule dev
#export PB_PORT="3030"
export PB_PASS="NONE"

############################################
#    General Helpers                       #
############################################

# NOTE: methods that should not be listed in rem() should have { on the same line as the method name

# helper in case I forget what exists, should just list all the functions
rem() {
    egrep '^[a-zA-Z_]+\(\)$' ~/.bashrc
    echo
    echo "Ruby Gem Dir: $(SHELL_SESSION_FILE= && rvm gemdir)" # NOTE: workaround to prevent apple session saving for subshells
    echo "crontab -e is written here /var/spool/cron/"
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

# Disable homebrew auto-updating of all installed kegs
export HOMEBREW_NO_AUTO_UPDATE=1

############################################
#    REMOTE SCRIPT STORAGE                 #
############################################

# Moves the HEAD of the 'deploy' branch to the latest revision of the specified branch
git_pin()
{
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
restart_unicorn()
{
   systemctl stop unicorn
   echo 'stopped...'
   sleep 1
   systemctl start unicorn
   echo 'started...'
   sleep 2
   systemctl status unicorn
}

# alt version for AWS instances
restart_unicorn()
{
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

staging_admin_on()
{
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
mysql_use_80()
{
  brew unlink mysql@5.7
  brew link mysql@8.0
  brew services restart mysql
  echo
  mysql --version
}

mysql_use_57()
{
  brew unlink mysql@8.0
  brew link mysql@5.7
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
  mysql --init-command="SET collation_connection = 'utf8mb4_general_ci';" -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2
}

con_prod_yaoi_db()
{
  mysql --init-command="SET collation_connection = 'utf8mb4_general_ci';" -h $PROD_CLUSTER_HOST -u ${MYSQL_YAOI_PROD_USER} -p${MYSQL_YAOI_PROD_PASS} yaoi
}

# NOTE: writable DB only
con_insights_db()
{
  mysql --init-command="SET collation_connection = 'utf8mb4_general_ci';" -h $PROD_CLUSTER_HOST -u ${MYSQL_INSIGHT_PROD_USER} -p${MYSQL_INSIGHT_PROD_PASS} insight
}

# for test/pre/staging etc
# TODO: from dev machine only works with direct IP address (see etc/hosts)
con_test_db()
{
  #echo "permissions issue! Connect from EC2 instance"
  #echo "mysql -h ${LABS_CLUSTER_HOST} -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}"
  mysql -h $LABS_CLUSTER_HOST -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}

  #mysql -h 172.30.1.139 -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}
}

# REM: the AWS version
# NOTE: "SET NAMES utf8mb4" is required due to mismatch between mysql5.7 and mysql8 client in how they display unicode characters
#       https://github.com/PyMySQL/mysqlclient/issues/504
con_pb_db()
{
  mysql --init-command="SET NAMES utf8mb4;" -h $PROD_CLUSTER_HOST -u ${MYSQL_PB_USER} -p${MYSQL_PB_PASS} productbible
}

############################################
#    Navigation Shortcuts                  #
############################################

chef()
{
cd ${VIZ_REPO_DIR}/chef-aws/VIZAWSOW/files/default/viz_rails_config/
}

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

git_manual_diff()
{
  path=$1
  REPO_ROOT=$(git rev-parse --show-toplevel) # example: /Users/matthewhively/vizlabs_repos/vizmule_rails

  if [ -z "$path" ]; then
    echo "USAGE: git_manual_diff [file_path]"
  elif [ -z "$REPO_ROOT" ]; then
    echo 'ERROR: Current working directory is not part of a GIT repo! Cannot continue'
  else
    filename=$(basename $path) # just the file itself
    rm /tmp/*.${filename}      # clear out any old copies

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
    echo "USAGE: diff_sublime_to_vizmule [file_path]" && return 1
  elif [ $is_sublime -eq 1 ]; then
    echo "Must be run from in the sublime/railsapp directory" && return 1
  fi

  echo "diffing ... $path $VIZ_REPO_DIR/vizmule_rails/railsapp/$path"
  sleep 2
  vimdiff $path $VIZ_REPO_DIR/vizmule_rails/railsapp/$path
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
awslogin()
{
echo "broken... TODO fix"
return
    PROFILE='default'
    [ -n "$1" ] && PROFILE=$1
    echo "logging in with $PROFILE"
    eval $(aws ecr get-login --profile $PROFILE --no-include-email)
    rm -f       /tmp/last_aws_login
    date +%s >> /tmp/last_aws_login
}
# usage awslogin [profile]

dockerlogin()
{
    AWS_DEFAULT_REGION='us-east-1'
    PROFILE='default'
    [ -n "$1" ] && PROFILE=$1

    # NOTE: this redis key is (by default) put into DB 0
    key="last_docker_login_$PROFILE"
    active=$(redis-cli exists $key)

    if [ $active -eq 1 ]; then
      # Doesn't matter how long remains
      echo "Docker $PROFILE is active"

    else
      echo "Login to Docker with $PROFILE"
      #eval $(aws ecr get-login --profile $PROFILE --no-include-email)
      aws ecr get-login-password --profile $PROFILE | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

      # Set a key to expire in 10 hours
      redis-cli setex $key 36000 1
    fi
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
  cp ~/.bashrc    ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.gemrc     ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.gitconfig ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.inputrc   ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.irbrc     ~/misc_repos/matthewhively.github.io/env_files/.
  cp ~/.vimrc     ~/misc_repos/matthewhively.github.io/env_files/.

  # TODO: sync some of .vim, but not all of it
  #cp -a ~/.vim    ~/misc_repos/matthewhively.github.io/env_files/.
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

rails_redshift_console()
{
# TODO: fix to automatically shift into vizmule project folder
  REDSHIFT_REMOTE='true' REDSHIFT_DB='production' REDSHIFT_USER=${DW_REDSHIFT_USER} REDSHIFT_PASSWORD=${DW_REDSHIFT_PASSWORD} rails c
}

# TODO: what is this exported for?
export EDITOR=vim

# set this to bogus? -- I think blank was just screwed up
#export APPLE_SUBS_PASS='BOGUS'
# init the APPLE_SUBS_PASS to the correct value, so it can be inherited by docker environment. (I think its ok to have it set for my local machine)
export APPLE_SUBS_PASS="$(egrep 'subscription_password' ${VIZ_REPO_DIR}/chef-aws/VIZAWSOW/files/default/viz_rails_config/settings.yml | egrep -o '[a-z0-9]+' | tail -n1)"

# Firebase/Firestore credentials via "Google Application Default Credentials"
#export GOOGLE_APPLICATION_CREDENTIALS="${VIZ_REPO_DIR}/vizmule_rails/railsapp/config/vizmule-9dca1dab322d.json"

# Maybe enable export of VIZ_RESQUE_BOT_TOKEN if needed (see bash_secrets)

# Turn on test environment debug logging
#USE_STDOUT_LOG=true
# :debug, :info, :warn, :error, :fatal, :unknown
#RAILS_LOG_LEVEL='debug'

# export RAILS_MYSQL_DEBUG=1    # to turn on MySQL level debug logging

# export EXTRA_SECTION_DEBUG=true  # enhance the debug logging in the section helper


############################################
#    ssh shortcuts for AWS                 #
############################################

# "aws ssm start-session" requires:
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

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

# ---- OLD ----

# Assuming csshX is installed and working:
### install instructions
### - make sure your xcode "Command Line Tools"  are up to date. (may need to install manually)
### --- xcode-select --install ???maybe???
### --- https://developer.apple.com/download/all/?q=xcode (after sign in to apple)
### - brew install csshx (or parera10/csshx/csshx if that fails)
# Connect to multiple instances at the same time with:
# csshX --login matthew host1 host2 ... hostX

##############################

# auto discovered local network servers
# pb
# dp
# labuntu  -- new up-to-date server for the future of digital_publishing
# webstage
# ...

##############################

# Adjust path
# TODO: if yarn or rvm are not in their proper path locations, move them there

YARN_PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"

# Check if the directory is already in the PATH
if [[ ":$PATH:" != *":$YARN_PATH:"* ]]; then
    # Add the directory to the PATH
    export PATH="$YARN_PATH:$PATH"
    echo "Added '$YARN_PATH' to the PATH."
else
    echo "$YARN_PATH is already in the PATH."
fi


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.

RVM_PATH="$HOME/.rvm/bin"

# Check if the directory is already in the PATH
if [[ ":$PATH:" != *":$RVM_PATH:"* ]]; then
    # Add the directory to the PATH
    export PATH="$PATH:$RVM_PATH"
    echo "Added '$RVM_PATH' to the PATH."
else
    echo "$RVM_PATH is already in the PATH."
fi

# TODO: it looks like this path adjustment is performed here & in .profile (maybe also elsewhere?)
# FIXME: where do these paths for ruby 2.5.5 come from?

# EXPERIMENTAL chruby
# prep:
#    mv ~/.rvm ~/.silenced-rvm; mv ~/.rvm-rubies ~/.rvm
#    mkdir ~/.rvm
#    cp -a ~/.silenced-rvm/rubies ~/.rvm/.

#source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh
#RUBIES+=(~/.rvm/rubies/*)
#source $(brew --prefix)/opt/chruby/share/chruby/auto.sh
#chruby ruby-2.5.3

# restore:
#    mv ~/.rvm ~/.rvm-chruby
#    mv ~/.silenced-rvm ~/.rvm
#    rm -rf ~/.rvm-chruby


