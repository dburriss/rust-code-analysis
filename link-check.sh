#!/bin/bash
LINK_REG='\[[^][ ]+]\((https?:\/\/[^()]+)\)'                         # regex for finding md links
declare -a FILES                                                      # indexed array
readarray -t FILES < <(find ./rust-code-analysis-book -name "*.md")   # get the markdown files

printf 'Scanning %s\n' "${FILES[0]}"
CUR_FILE="${FILES[0]}"
#grep -oP -e LINK_REG "${FILES[0]}"

FILE="./rust-code-analysis-book/src/developers/new-language.md"
printf 'Scanning %s\n' "${FILE}"
FILE_MD_LINKS=($(grep -oE "${LINK_REG}" "${FILE}"))                   # -E extended regex, -o output only match
echo "${FILE_MD_LINKS[0]}"
# foreach file get links in it
#grep -oP "\[\K([^]]*)" <<< "${FILE_MD_LINKS[0]}"
URI_OR_PATH=$(grep -oP "\(\K(https?:\/\/[^()]+)" <<< "${FILE_MD_LINKS[0]}")
echo "${URI_OR_PATH}"

if [[ $URI_OR_PATH = http* ]]
then
  echo "URI"
else
  if [[ $URI_OR_PATH = /* ]]
  then
    echo "PATH"
  fi
fi
  # test URI is not 404
# for text part if starts with / and ends with .rs check if it exists

# for each link check that it is not 404