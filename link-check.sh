#!/bin/bash

# accumulators and constants
MD_LINK_REGEX='\[[^][]+]\(https?:\/\/[^()]+\)'                        # regex for finding md links in text
file_count=0
md_link_count=0
path_count=0
path_fail_count=0
uri_count=0
uri_fail_count=0
exit_code=0

# success log - always prints
# param 1: string to log
function success () {
  local green=$'\e[0;32m'
  local stop=$'\e[m'
  echo "$green$1$stop"
}

# info log - always prints
# param 1: string to log
function info () {
  local yellow=$'\e[1;33m'
  local stop=$'\e[m'
  echo "$yellow$1$stop"
}

# trace log -
# param 1: string to log
function trace () {
  local BLUE=$'\e[0;34m'
  local stop=$'\e[m'
  local verbose=$(($2))
  if [ $verbose -ge 1 ]
  then
  echo "$BLUE$1$stop"
  fi
}

# debug log - prints
# param 1: string to log
# Always prints
function debug () {
  local verbose=$(($2))
  if [ $verbose -ge 2 ]
  then
  echo "$1"
  fi
}

function error () {
  local RED=$'\e[1;31m'
  local stop=$'\e[m'
  echo "$RED$1$stop"
}

function check_file () {
  file=$1
  info "Scanning $file"
  declare -a file_md_links
  readarray -t file_md_links < <(grep -oP "${MD_LINK_REGEX}" "${file}")   # -P Perl regex, -o output only match
  md_link_count=$(($md_link_count+${#file_md_links[*]}))
  for md_link in "${file_md_links[@]}";
  do
    trace "  Found: $md_link" $verbose

    # check uri
    uri=$(grep -oP "\(\K(https?:\/\/[^()]+)" <<< "${md_link}")
    if [[ $uri = http* ]]
    then
      uri_count=$(($uri_count+1))
      req=$(curl -LI "${uri}" -o /dev/null -w '%{http_code}\n' -s)
      if [[ ! $((req)) == 200 ]]
      then
        exit_code=1
        error "    BAD URL ${uri}"
        uri_fail_count=$(($uri_fail_count+1))
      else
        debug "    HTTP status $req ($uri)" $verbose
      fi
    fi

    # check path
    file_path=$(grep -oP "\[\K([^]]*)" <<< "${md_link}")
    if [[ "$file_path" == */* || "$file_path" == *.* ]]
    then
      path_count=$(($path_count+1))
      if [[ "${file_path:0:1}" == "/" ]]
      then
        file_path="${file_path:1}"
      fi
      if [[ ! -f $file_path && ! -d $file_path ]]
      then
        exit_code=1
        error "    BAD PATH ${file_path}"
        path_fail_count=$(($path_fail_count+1))
      else
        debug "    File found: $file_path" $verbose
      fi
    fi
  done
}

# set logging verbosity level
if [[ $1 = "-v" ]]
then verbose=1
elif [[ $1 = "-vv" ]]
then verbose=2
else verbose=0
fi

debug "Verbose $verbose"

declare -a files                                                          # indexed array of MD files
readarray -t files < <(find ./rust-code-analysis-book -name "*.md")       # get the markdown files
file_count=$(($file_count+${#files[*]}))
for file in "${files[@]}"
do
  check_file $file
done

# Print our report
echo "====================================="
info "Found $md_link_count MD links across $file_count files."

if [[ $uri_fail_count == 0 ]]
then
  success "Failed links: $uri_fail_count/$uri_count"
else
  error "Failed links: $uri_fail_count/$uri_count"
fi

if [[ $path_fail_count == 0 ]]
then
  success "Failed paths: $path_fail_count/$path_count"
else
  error "Failed paths: $path_fail_count/$path_count"
fi
echo "====================================="
exit $exit_code

# possible improvement keep cache of checked values?