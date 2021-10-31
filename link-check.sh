#!/bin/bash
RED=$'\e[1;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
STOP=$'\e[m'
COUNT=0
EXIT=0
MD_LINK_REGEX='\[[^][]+]\(https?:\/\/[^()]+\)'                        # regex for finding md links in text
function info () {
  echo "$YELLOW$1$STOP"
}
function trace () {
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
  echo "$RED$1$STOP"
}

if [[ $1 = "-v" ]]
then VERBOSE=1
elif [[ $1 = "-vv" ]]
then VERBOSE=2
else VERBOSE=0
fi

echo "Verbose $VERBOSE"
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
    REQ=$(curl -LI "${URI}" -o /dev/null -w '%{http_code}\n' -s)
    if [[ ! $((REQ)) == 200 ]]
    then
      error "    BAD URL ${URI}"
      EXIT=1
    else
      debug "    HTTP status $REQ ($URI)" $VERBOSE
    fi
  fi

  # check path
  FILE_PATH=$(grep -oP "\[\K([^]]*)" <<< "${MD_LINK}")
  if [[ ${FILE_PATH:0:1} = "/" ]]
  then
    # trim /
    FILE_PATH="${FILE_PATH:1}"
    if [[ ! -f $FILE_PATH && ! -d $FILE_PATH ]]
    then
      error "  $RED BAD PATH$STOP ${FILE_PATH}"
      EXIT=1
    else
      debug "    File found: $FILE_PATH" $VERBOSE
    fi
  fi
  done
done

echo "Total links found $COUNT"

exit $EXIT

# keep cache of checked values
# what if not a leading / but still a path