#!/usr/bin/env bash
# Note that some commands have different behavior on MacOS
#
# Author:       chengdol
# Description:  Generate list of blogs for reviewing.
#
###################################################################
#set -ueo pipefail
#set -x

# last day boundary
declare -i day=14
declare -a sha_list=($(git rev-list HEAD --since=${day}days))
#declare -p sha_list

URL_PREFIX="https://chengdol.github.io" #2021/01/02/book-infra-as-code/
REVIEW_FILE="./_posts/review-list.md"

cat <<_EOF > ${REVIEW_FILE}
---
title: Blog Review List
date: {{ DATE }}
---

There are **{{ NUM }}** blogs written or updated in last **{{ DAY }}** days that need to be reviewed:

_EOF

files=""
for((i=1;i<${#sha_list[@]};i++))
do 
  # only count .md file
  tmp=$(git diff --name-only --diff-filter=ACMR ${sha_list[i]} ${sha_list[i-1]} \
          | grep -E ".+\.md" \
          | grep -v -E "review-list\.md" \
          | grep -v -E "inprogress\.md" \
          || echo "")
  files="$tmp $files"
done

declare -a file_list=($(echo $files | tr " " "\n" | sort | uniq))
for ((i=0;i<${#file_list[@]};i++))
do
  # retrieve specified line
  title=$(sed -n -e 2p ${file_list[i]})

  date=$(sed -n -e 3p ${file_list[i]})
  date=${date##"date: "}
  date=${date%%[[:space:]]*}
  date=${date//-/\/}

  file_name=${file_list[i]##"_posts/"}
  file_name=${file_name%".md"}

  echo "- [${title##"title: "}](${URL_PREFIX}/${date}/${file_name})" >> ${REVIEW_FILE}
done

sed -i "" -e "s#{{ DATE }}#$(date '+%Y-%m-%d %H:%M:%S')#g; s#{{ NUM }}#${#file_list[@]}#g; s#{{ DAY }}#${day}#g" ${REVIEW_FILE}
