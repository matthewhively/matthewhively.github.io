############################################
#    COMMON SHORTCUTS                      #
############################################
alias ls='ls -a -G -p -F'
alias ll='ls -a -G -p -F -l'
alias grep='/usr/bin/egrep -n -S --color --exclude-dir=coverage --exclude-dir=vizmule_cache_fldr --exclude=*.swp'
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

SN=${0} # get the name of the currently running program (in this case bash)
#SN=${0:1} #trims the shell name from "-bash" -> "bash"
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

# helper in case I forget what exists, should just list all the functions
rem()
{       
    egrep '^[a-zA-Z_]+\(\)$' ~/.bashrc
    echo "Ruby Gem Dir: $(SHELL_SESSION_FILE= && rvm gemdir)" # NOTE: workaround to prevent apple session saving for subshells
    echo "crontab -e is written here /var/spool/cron/"
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

# This utility is not installed on macos, but is on our linux machines
alias sensible-pager='less'

# override "man" command so it will work with built-ins as well
man () {
    case "$(type -t -- "$1")" in
    builtin|keyword)
        help -m "$1" | sensible-pager
        ;;
    *)
        command man "$@"
        ;;
    esac
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

con_prod_db()
{
  mysql --ssl-mode=disabled -h $PROD_CLUSTER_HOST -u ${MYSQL_VIZ_PROD_USER} -p${MYSQL_VIZ_PROD_PASS} viz2
}

con_prod_yaoi_db()
{
  mysql --ssl-mode=disabled -h $PROD_CLUSTER_HOST -u ${MYSQL_YAOI_PROD_USER} -p${MYSQL_YAOI_PROD_PASS} yaoi
}

# NOTE: writable DB only
con_insights_db()
{
  mysql -h $PROD_CLUSTER_HOST -u ${MYSQL_INSIGHT_PROD_USER} -p${MYSQL_INSIGHT_PROD_PASS} insight
}

# for test/pre/staging etc
# TODO: not currently working from dev machine... some kinda permissions issue
con_test_db()
{
  #mysql --ssl-mode=disabled -h $LABS_CLUSTER_HOST -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}
  echo "permissions issue! Connect from EC2 instance"
  echo "mysql -h ${LABS_CLUSTER_HOST} -u ${MYSQL_LABS_USER} -p${MYSQL_LABS_PASS}"
}

# REM: the AWS version
# NOTE: "SET NAMES utf8mb4" is required due to mismatch between mysql5.7 and mysql8 client in how they display unicode characters
#       https://github.com/PyMySQL/mysqlclient/issues/504
con_pb_db()
{
  mysql --init-command="SET NAMES utf8mb4;" --ssl-mode=disabled -h $PROD_CLUSTER_HOST -u ${MYSQL_PB_USER} -p${MYSQL_PB_PASS} productbible
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

git_help()
{
  echo "USEFUL GIT COMMANDS"
  echo "git push origin --delete <BRANCH>   ::: delete remote branch"
  echo "git remote prune origin (git_prune) ::: cleanup remote refrences to branches that no longer exist"
  #echo ""
}

alias vdgd="git difftool --tool=vimdiff --no-prompt"
alias vdgds="git difftool --tool=vimdiff --no-prompt --staged"

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

# ---- VizMule ----

con_viz_prod()
{
  # viz-group-1-1b
  con_viz_ectwo "ec2-34-203-23-255.compute-1.amazonaws.com" "matthew" $1
}

con_viz_admin()
{
  con_viz_ectwo "ec2-34-234-251-231.compute-1.amazonaws.com" "matthew" $1
}
con_viz_bg()
{
  con_viz_ectwo "ec2-34-203-157-204.compute-1.amazonaws.com" "matthew" $1
}

con_viz_staging()
{
  con_viz_ectwo "ec2-34-207-48-42.compute-1.amazonaws.com" "matthewhively" $1
}

con_viz_approvals()
{
  con_viz_ectwo "ec2-3-229-246-66.compute-1.amazonaws.com" "matthewhively" $1
}

# ---- long term testing instances ----
con_viz_test()
{
  con_viz_ectwo "ec2-35-172-31-109.compute-1.amazonaws.com" "matthewhively" $1
}

con_viz_pre()
{
  con_viz_ectwo "ec2-35-171-120-154.compute-1.amazonaws.com" "matthewhively" $1
}

con_viz_pre1()
{
  con_viz_ectwo "ec2-54-81-181-200.compute-1.amazonaws.com" "matthewhively" $1
}

con_pb_pre()
{
  con_viz_ectwo "ec2-34-203-80-109.compute-1.amazonaws.com" "matthewhively" $1
}


# ---- SUBLIME ----

con_sub_staging()
{
  con_viz_ectwo "ec2-34-235-11-133.compute-1.amazonaws.com" "matthewhively" $1
}
con_sub_admin()
{
  con_viz_ectwo "ec2-54-85-245-174.compute-1.amazonaws.com" "matthew" $1
}

# For sublime
# Either group 1 or group 2 may be online.
# only need to connect to one of the 2 hosts in the group.
con_sub_prod()
{
  hostname=$(curl -s -k 'https://www.sublimemanga.com/info' | jq .host)
  group=${hostname: -5:1} # 1 or 2
  if [ $group -eq 1 ]; then
    con_viz_ectwo "ec2-35-174-206-170.compute-1.amazonaws.com" "matthew" $1
    # ALT: ec2-100-25-126-173.compute-1.amazonaws.com
  elif [ $group -eq 2 ]; then
    con_viz_ectwo "ec2-52-205-32-217.compute-1.amazonaws.com" "matthew" $1
    # ALT: ec2-18-235-5-53.compute-1.amazonaws.com
  else
    echo "Unknown host: host: '${hostname}', group: '${group}'"
    return 1
  fi
}

# ---- OTHER ----

# sid's special lightsail instance for interviewees
con_lightsail()
{ 
  ssh -i ~/.ssh/viz_external_lightsail_key1.pem  centos@54.244.63.48
}

# insights.viz.com (aws version)
con_viz_insights()
{
  con_viz_ectwo "ec2-35-170-154-4.compute-1.amazonaws.com" "matthew" $1
} 
  
# Just as a reminder
con_insights_internal()
{
  ssh insightsinternal
}

# ---- GENERIC ----
# REM: use the same user_name as for logging into AWS console 
con_viz_ectwo()
{
  # $1 - public IP
  # $2 - user_name
  # $3 - ssh arguments

  if [ -z "$1" ]; then
    echo "USAGE: con_viz_ec2 <public_ip> [user_name] [ssh_args]"
    return 1
  fi

  UN='matthew' # productionAWS
  if [ -n "$2" ]; then
    UN=$2
  fi

  #echo "ssh $3 -i ~/.ssh/mhively_rsa.pub $UN@$1"
  ssh $3 -i ~/.ssh/mhively_rsa $UN@$1
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

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

