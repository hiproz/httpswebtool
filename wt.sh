#!/bin/bash

##  命令格式： wt.sh action domain  webroot  nginx-config-path 1@2.com
#eg: 
#./wt.sh add blog.goodmemory.cc /data/wwwroot/blog_gm /usr/local/nginx/conf/vhost 1@2.com
#./wt.sh remove blog.goodmemory.cc

# action: add remove 
#
action=$1
domain=$2
webroot=$3
nginx_conf_path=$4
email=$5

if [ ! -d "~/.wt" ]; then
    mkdir -p ~/.wt
fi

if [ "$action" = "add" ]; then
    echo "wt.sh [action] [domain] [webroot] [nginx-config-path] [email in letsencrypt]"
    if [  $# -lt 5 ]; then
        echo "invalid params"
        exit 0
    fi

    echo "domain:$domain, webroot:$webroot, nginx_conf_path:$nginx_conf_path"
    if [ ! -d "$webroot" ]; then
        mkdir -p $webroot
    fi

    \cp -rf index.html $webroot

    if [ ! -d "$nginx_conf_path" ]; then
        echo "invalid nginx config path"
	exit 0
    fi

    # 生成默认的http nginx 配置，确保 certonly模式网络能访问，当然这个前提是已经把域名的dns配置好了
    ## 构建http网络环境
    ## 使用 sed 命令将文件 a 中的 BBB 替换为 domain 的值，将 AAA 替换为 webroot 的值，并将结果输出到 domain.conf 文件
    sed "s|BBB|$domain|g; s|AAA|$webroot|g" default-http.conf > $domain.conf

    mv $domain.conf $nginx_conf_path
    nginx -s reload 
    echo "after reload the nginx,please test the http://$domain"
    
    #check the httpwebsite
    URL="http://$domain"

    # 使用curl获取HTTP响应码
    response_code=$(curl -o /dev/null -s -w "%{http_code}\n" "$URL")
    
    # 检查响应码是否为200
    if [ "$response_code" -eq 200 ]; then
        echo "Website is reachable and returns HTTP 200"
        # 在这里可以继续执行其他命令
    else
        echo "Please check the web service, the web site isn't reachable"
        echo "Received HTTP code: $response_code"
        exit 1
    fi
    
    # 解决重复执行的场景，每次先强制清除证书
    find /etc/letsencrypt  -name "*$domain*" -print0 | xargs -0 -I {} sh -c 'echo "Removing: {}"; rm -rf "{}"'

    # 开始生成https证书
    # 执行certbot命令
    certbot certonly --non-interactive  --agree-tos --email $email --webroot -w $webroot -d $domain |grep .pem > ~/.wt/$domain

    # ~/.wt/$domain 的内容参考：
    #Certificate is saved at: /etc/letsencrypt/live/xxx.com/fullchain.pem
    #Key is saved at:         /etc/letsencrypt/live/xxx.com/privkey.pem
    
    #我们要提取冒号后面的内容
    ## 分别获取fullchain.pem 和 privkey.pem
    full_pem_path=$(head -1 ~/.wt/$domain|awk -F':[[:space:]]+' '{print $2}')
    private_pem_path=$(tail -1 ~/.wt/$domain|awk -F':[[:space:]]+' '{print $2}')
    echo "letsencrypt full pem path:$full_pem_path"
    echo "letsencrypt private pem path:$private_pem_path"
    echo "certbot success!"
    
    ## 到这里我们已经成功获取letsencrypt的https证书了，接下来就是生成最终的nginx conf 文件
    sed "s|BBB|$domain|g; s|AAA|$webroot|g; s|CCC|$full_pem_path|g; s|DDD|$private_pem_path|g" default-https.conf > $domain.conf

    mv $domain.conf $nginx_conf_path
    nginx -s reload 
    echo "nginx reload success!"
elif [ "$action" = "remove"  ]; then
    cat ~/.wt/$domain
    find /etc/letsencrypt  -name "*$domain*" -print0 | xargs -0 -I {} sh -c 'echo "Removing: {}"; rm -rf "{}"'
    rm -f ~/.wt/$domain
    timestamp=$(date +"%y%m%d%H%M%S")
    mv "$nginx_conf_path/$domain.conf" "$nginx_conf_path/$domain.conf-$timestamp.bak"
    nginx -s reload
    echo "remove finish!"
else
    echo "please input invalid params!"
    echo "eg:"
    echo "./wt.sh add blog.goodmemory.cc /data/wwwroot/blog_gm /usr/local/nginx/conf/vhost 1@2.com"
    echo "./wt.sh remove blog.goodmemory.cc"
fi
