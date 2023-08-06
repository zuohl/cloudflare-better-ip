#!/bin/bash

dir_html="html"
mkdir -p $dir_html

folder_list=(cloudflare_country cloudfront_country)

for folder in ${folder_list[@]}; do
    # 创建空的json对象
    json="{"

    # 读取目录下的所有文件
    files=$(ls $folder)

    # 遍历每个文件
    for file in $files
    do
        # 获取文件名对应的国家代码
        countryCode=$(echo "$file" | cut -d "." -f 1)
        # 按latency排序并提取前十个
        sorted_lines=$(grep -v ' 0ms ' $folder/$file | sort -t'|' -k4,4n | head -n 10)
        if [ -z "$sorted_lines" ]; then
            continue
        fi
        
        json+="\"$countryCode\": ["
        while read -r line; do
            ip=$(echo "$line" | cut -d'|' -f1)
            cf_ip=$(echo "$line" | cut -d'|' -f2)
            country=$(echo "$line" | cut -d'|' -f3)
            latency=$(echo "$line" | cut -d'|' -f4)
            type=$(echo "$line" | cut -d'|' -f5)
            time=$(echo "$line" | cut -d'|' -f6)

            # 创建每行数据的json对象
            jsonLine="{\"ip\": \"$ip\", \"cf-ip\": \"$cf_ip\", \"country\": \"$country\", \"latency\": \"$latency\", \"type\": \"$type\", \"time\": \"$time\"}"
    
            # 将json对象追加到数组中
            json+="$jsonLine,"
        done <<< "$sorted_lines"
    
        json=${json%,}
        json+="],"
    done

    json=${json%,}
    json+="}"

    echo $json > $dir_html/${folder}_ip.json
done