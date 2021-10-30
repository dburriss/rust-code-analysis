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
#grep -oP "\[\K([^]]*)" <<< "${FILE_MD_LINKS[0]}"
POSSIBLE_FILE=$(grep -oP "\[\K([^]]*)" <<< "${FILE_MD_LINKS[0]}")
echo "${POSSIBLE_FILE}"
# foreach file get links in it


# for text part if starts with / and ends with .rs check if it exists
# for each link check that it is not 404