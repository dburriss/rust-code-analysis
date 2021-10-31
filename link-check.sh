#!/bin/bash
RED=$'\e[1;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
STOP=$'\e[m'

MD_LINK_REGEX='\[[^][ ]+]\((https?:\/\/[^()]+)\)'                     # regex for finding md links in text
declare -a FILES                                                      # indexed array of MD files
readarray -t FILES < <(find ./rust-code-analysis-book -name "*.md")   # get the markdown files
for FILE in "${FILES[@]}"
do
  echo "$YELLOW Scanning $FILE $STOP"
  FILE_MD_LINKS=($(grep -oE "${MD_LINK_REGEX}" "${FILE}"))                   # -E extended regex, -o output only match
  #echo "${FILE_MD_LINKS[0]}"
  # foreach file get links in it
  #grep -oP "\[\K([^]]*)" <<< "${FILE_MD_LINKS[0]}"
  for MD_LINK in "${FILE_MD_LINKS[@]}";
  do
  echo "  Found:$BLUE $MD_LINK $STOP"

  # check URI
  URI=$(grep -oP "\(\K(https?:\/\/[^()]+)" <<< "${MD_LINK}")
  if [[ $URI = http* ]]
  then
    REQ=$(curl -LI "${URI}" -o /dev/null -w '%{http_code}\n' -s)
    echo "HTTP Status $REQ"
    if [[ $((REQ)) -ge 399 ]]
    then
      echo "  $RED BAD URL$STOP ${URI}"
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
      echo "  $RED BAD PATH$STOP ${FILE_PATH}"
    fi
  fi
  done
done



  # test URI is not 404
# for text part if starts with / and ends with .rs check if it exists

# for each link check that it is not 404

# handle exitcode if something wrong
# keep cache of checked values