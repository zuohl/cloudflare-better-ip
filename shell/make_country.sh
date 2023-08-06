#!/bin/bash
folder_list=(cloudflare cloudfront)

for folder in ${folder_list[@]}; do
  folder_country="${folder}_country"
  rm -rf $folder_country
  mkdir -p $folder_country
  for file in $folder/*.txt; do
    while IFS= read -r line; do
      country=$(echo "$line" | awk -F"|" '{print $3}' | awk '{$1=$1};1')
      echo "$line" >> "$folder_country/$country.txt"
    done < "$file"
  done
done
