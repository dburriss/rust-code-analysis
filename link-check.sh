#!/bin/bash
RED=$'\e[1;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
STOP=$'\e[m'

LINK_REG='\[[^][ ]+]\((https?:\/\/[^()]+)\)'                          # regex for finding md links
declare -a FILES                                                      # indexed array
readarray -t FILES < <(find ./rust-code-analysis-book -name "*.md")   # get the markdown files

printf 'Scanning %s\n' "${FILES[0]}"
CUR_FILE="${FILES[0]}"
#grep -oP -e LINK_REG "${FILES[0]}"

FILE="./rust-code-analysis-book/src/developers/new-language.md"
echo "$YELLOW Scanning $FILE $STOP"
FILE_MD_LINKS=($(grep -oE "${LINK_REG}" "${FILE}"))                   # -E extended regex, -o output only match
#echo "${FILE_MD_LINKS[0]}"
# foreach file get links in it
#grep -oP "\[\K([^]]*)" <<< "${FILE_MD_LINKS[0]}"
for MD_LINK in "${FILE_MD_LINKS[@]}";
do
echo "$BLUE $MD_LINK $STOP"
# check URI
URI=$(grep -oP "\(\K(https?:\/\/[^()]+)" <<< "${MD_LINK}")

if [[ $URI = http* ]]
then
  #echo "Check URI ${URI}"
  if curl -s --head  --request GET "${URI}" | grep "404 Not Found" > /dev/null
  then
    echo "$RED  BAD URL ${URI} $STOP"
  fi
fi

# check path
FILE_PATH=$(grep -oP "\[\K([^]]*)" <<< "${MD_LINK}")
if [[ ${FILE_PATH:0:1} = "/" ]]
then
  # echo "Check PATH ${FILE_PATH}"
  # trim /
  FILE_PATH="${FILE_PATH:1}"
  # echo "Check FILE_PATH ${FILE_PATH}"
  # TEST_PATH=$(readlink -f "$FILE_PATH")
  if [[ ! -f $FILE_PATH && ! -d $FILE_PATH ]]
  then
    echo "$RED  BAD PATH ${FILE_PATH} $STOP"
  fi
fi
done

  # test URI is not 404
# for text part if starts with / and ends with .rs check if it exists

# for each link check that it is not 404

# TODO: handle exitcode if something wrong
# TODO: keep cache of checked values