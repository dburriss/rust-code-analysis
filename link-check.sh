#!/bin/bash

COUNT=0
PATH_COUNT=0
PATH_FAIL_COUNT=0
URI_COUNT=0
URI_FAIL_COUNT=0
EXIT=0
MD_LINK_REGEX='\[[^][]+]\(https?:\/\/[^()]+\)'                        # regex for finding md links in text
function success () {
  local GREEN=$'\e[0;32m'
  local STOP=$'\e[m'
  echo "$GREEN$1$STOP"
}
function info () {
  local YELLOW=$'\e[1;33m'
  echo "$YELLOW$1$STOP"
}
function trace () {
  local BLUE=$'\e[0;34m'
  local STOP=$'\e[m'
  local VERBOSE=$(($2))
  if [ $VERBOSE -ge 1 ]
  then
  echo "$BLUE$1$STOP"
  fi
}
function debug () {
  local VERBOSE=$(($2))
  if [ $VERBOSE -ge 2 ]
  then
  echo "$1"
  fi
}
function error () {
  local RED=$'\e[1;31m'
  local STOP=$'\e[m'
  echo "$RED$1$STOP"
}

if [[ $1 = "-v" ]]
then VERBOSE=1
elif [[ $1 = "-vv" ]]
then VERBOSE=2
else VERBOSE=0
fi

debug "Verbose $VERBOSE"
declare -a FILES                                                      # indexed array of MD files
readarray -t FILES < <(find ./rust-code-analysis-book -name "*.md")   # get the markdown files
for FILE in "${FILES[@]}"
do
  info "Scanning $FILE"
  declare -a FILE_MD_LINKS
  readarray -t FILE_MD_LINKS < <(grep -oP "${MD_LINK_REGEX}" "${FILE}")                   # -E extended regex, -o output only match
  COUNT=$(($COUNT+${#FILE_MD_LINKS[*]}))
  for MD_LINK in "${FILE_MD_LINKS[@]}";
  do
    trace "  Found: $MD_LINK" $VERBOSE

    # check URI
    URI=$(grep -oP "\(\K(https?:\/\/[^()]+)" <<< "${MD_LINK}")
    if [[ $URI = http* ]]
    then
      URI_COUNT=$(($URI_COUNT+1))
      REQ=$(curl -LI "${URI}" -o /dev/null -w '%{http_code}\n' -s)
      if [[ ! $((REQ)) == 200 ]]
      then
        EXIT=1
        error "   BAD URL ${URI}"
        URI_FAIL_COUNT=$(($URI_FAIL_COUNT+1))
      else
        debug "    HTTP status $REQ ($URI)" $VERBOSE
      fi
    fi

    # check path
    FILE_PATH=$(grep -oP "\[\K([^]]*)" <<< "${MD_LINK}")
    if [[ "$FILE_PATH" == */* || "$FILE_PATH" == *.* ]]
    then
      PATH_COUNT=$(($PATH_COUNT+1))
      if [[ "${FILE_PATH:0:1}" == "/" ]]
      then
        FILE_PATH="${FILE_PATH:1}"
      fi
      if [[ ! -f $FILE_PATH && ! -d $FILE_PATH ]]
      then
        EXIT=1
        error "   BAD PATH ${FILE_PATH}"
        PATH_FAIL_COUNT=$(($PATH_FAIL_COUNT+1))
      else
        debug "    File found: $FILE_PATH" $VERBOSE
      fi
    fi
  done
done
echo "============================="
info "Total MD links found: $COUNT"

info "Links checked: $URI_COUNT"
if [[ $URI_FAIL_COUNT == 0 ]]
then
  success "Failed links: $URI_FAIL_COUNT"
else
  error "Failed links: $URI_FAIL_COUNT"
fi

info "Paths checked: $PATH_COUNT"
if [[ $PATH_FAIL_COUNT == 0 ]]
then
  success "Failed paths: $PATH_FAIL_COUNT"
else
  error "Failed paths: $PATH_FAIL_COUNT"
fi
echo "============================="
exit $EXIT

# keep cache of checked values