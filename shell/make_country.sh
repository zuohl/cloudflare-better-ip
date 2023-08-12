#!/bin/bash
folder_list=(cloudflare cloudfront)

for folder in ${folder_list[@]}; do
  folder_country="${folder}_country"
  rm -rf $folder_country
  mkdir -p $folder_country

  input_file="TOP100.txt"
  cat $folder/*.txt | grep -v ' 0ms ' | sort -t'|' -k4,4n | head -n 100 > $folder_country/$input_file
    # 读取txt文件内容
  content=$(cat $folder_country/$input_file)

  # 解析IP地址并去重
  ip_addresses=$(echo "$content" | awk '{gsub(/:.*/, "", $1); print $1}')

  # 构建POST请求数据
  post_data=$(echo "$ip_addresses" | awk '{printf "\"%s\",\n", $1}' | sed '$s/,$//')
  post_data="[$post_data]"

  # 查询接口返回结果
  api_url="http://ip-api.com/batch?fields=countryCode,query,isp"
  query=$(curl -s -X POST --data "$post_data" $api_url)
  # echo "$query"

  # 提取查询结果中的国家代码
  country_codes=$(echo "$query" | jq -r '.[].countryCode')

  # 替换txt文件中缺失的国家代码
  codes_array=()
  while IFS= read -r code; do
    codes_array+=("$code")
  done <<< "$country_codes"
  # echo "${codes_array[@]}"

  # 逐行处理txt文件内容并替换缺失的国家代码
  output=""
  count=0
  while IFS= read -r line; do
    # 将 |  | 替换为目标内容
    line="${line/|  |/| ${codes_array[count]} |}"
    # echo "$line"
    if [ $count -ne 0 ]; then
      output+=$'\n'
    fi
    output+="$line"
    count=$((count + 1))
  done <<< "$content"

  # 输出结果
  echo "$output" > $folder_country/$input_file

  while IFS= read -r line; do
    country=$(echo "$line" | awk -F"|" '{print $3}' | awk '{$1=$1};1')
    # echo "$country"
    echo "$line" >> "$folder_country/$country.txt"
  done < "$folder_country/$input_file"

done
