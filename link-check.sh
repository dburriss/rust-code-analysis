#!/bin/bash

#
# This script checks the markdown links in all markdown files.
# param 1: [optioal] [flag] -v or -vv to enable debugging or tracing
# param 2: [optional] path to a specific file to check. If not present, will search for *.md
# It will match all [desc](https?...) patterns in markdown files.
# 'desc' can be a directory or file and it will check it exists.
# exist code 1 if files or links not found.
# Examples:
# ./link-check.sh -v
# ./link-check.sh -vv ./path/to/markdown.md
#

#=============================
# accumulators and constants
#=============================
MD_LINK_REGEX='\[[^][]+]\(https?:\/\/[^()]+\)'                        # regex for finding md links in text
file_count=0
md_link_count=0
path_count=0
path_fail_count=0
uri_count=0
uri_fail_count=0
exit_code=0

#=============================
# general functions
#=============================

# success - always prints
# param 1: the string to print
function success () {
  local green=$'\e[0;32m'
  local stop=$'\e[m'
  echo "$green$1$stop"
}

# info - always prints
# param 1: the string to print
function info () {
  local yellow=$'\e[1;33m'
  local stop=$'\e[m'
  echo "$yellow$1$stop"
}

# trace - prints when verbosity on 1 or higher
# param 1: the string to print
function trace () {
  local BLUE=$'\e[0;34m'
  local stop=$'\e[m'
  local verbose=$(($2))
  if [ $verbose -ge 1 ]
  then
  echo "$BLUE$1$stop"
  fi
}

# debug - prints when verbosity on 2
# param 1: the string to print
function debug () {
  local verbose=$(($2))
  if [ $verbose -ge 2 ]
  then
  echo "$1"
  fi
}

# error - always prints but should be used only for errors
# param 1: the string to print
function error () {
  local RED=$'\e[1;31m'
  local stop=$'\e[m'
  echo "$RED$1$stop"
}

#=============================
# script specific functions
#=============================

# check_uri - pulls out the link and checks returns 200 OK
# param 1: markdown link string eg "[desc](link)"
function check_uri () {
  # check uri
  md_link=$1
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
}

# check_path - checks if desc points to a local file or directory and checks it is valid
# param 1: markdown link string eg "[desc](link)"
function check_path () {
  md_link=$1
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
}

# check_file - checks the path and link of all markdown links in the file
# param 2: the path to the markdown file to check
function check_file () {
  file=$1
  info "Scanning $file"
  declare -a file_md_links
  readarray -t file_md_links < <(grep -oP "${MD_LINK_REGEX}" "${file}")   # -P Perl regex, -o output only match
  md_link_count=$(($md_link_count+${#file_md_links[*]}))
  for md_link in "${file_md_links[@]}";
  do
    trace "  Found: $md_link" $verbose

    check_uri "$md_link"
    check_path "$md_link"

  done
}

#=============================
# execute script
#=============================

# set logging verbosity level
if [[ $1 = "-v" ]]
then verbose=1
elif [[ $1 = "-vv" ]]
then verbose=2
else verbose=0
fi

debug "Verbose $verbose"
if [[ $verbose == 0 && "$1" == *.md ]] ; then single_md_file="$1" ; fi
if [[ $verbose -gt 0 && "$2" == *.md ]] ; then single_md_file="$2" ; fi
echo "file $single_md_file | $1 | $2"
# if a md single file check that, else loop through all md files
if [[ -v single_md_file ]]
then
  # single file
  check_file "$single_md_file"
  file_count=1
else 
  # get all markdown files and check them
  declare -a files                                                          # indexed array of MD files
  readarray -t files < <(find ./rust-code-analysis-book -name "*.md")       # get the markdown files
  file_count=$(($file_count+${#files[*]}))
  for file in "${files[@]}"
  do
    check_file $file
  done
fi
# Print our report
echo "====================================="
info "Found $md_link_count MD links across $file_count files."

if [[ $uri_fail_count == 0 ]]
then
  success "Broken links: $uri_fail_count/$uri_count"
else
  error "Broken links: $uri_fail_count/$uri_count"
fi

if [[ $path_fail_count == 0 ]]
then
  success "Broken paths: $path_fail_count/$path_count"
else
  error "Broken paths: $path_fail_count/$path_count"
fi
echo "====================================="
exit $exit_code
