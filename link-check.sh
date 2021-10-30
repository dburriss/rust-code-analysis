#!/bin/bash
LINK_REG='\[[^][]+]\((https?://[^()]+)\)'                           # regex for finding md links
declare -a FILES                                                      # indexed array
readarray -t FILES < <(find ./rust-code-analysis-book -name "*.md")   # get the markdown files

printf 'Scanning %s\n' "${FILES[0]}"
CUR_FILE="${FILES[0]}"
grep -oP -e LINK_REG "${FILES[0]}"

FILE="./rust-code-analysis-book/src/developers/new-language.md"
printf 'Scanning %s\n' "${FILE}"
grep -Eo "${LINK_REG}" "${FILE}"

# foreach file get links in it


# for text part if starts with / and ends with .rs check if it exists
# for each link check that it is not 404