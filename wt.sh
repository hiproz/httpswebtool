#!/bin/bash

##  命令格式： wt.sh action domain  webroot  nginx-config-path
#eg: 
#./wt.sh add blog.goodmemory.cc /data/wwwroot/blog_gm /usr/local/nginx/conf/vhost
#./wt.sh remove blog.goodmemory.cc

# action: add remove 
#
action=$1
domain=$2
webroot=$3
nginx_conf_path=$4

if [ ! -d "~/.wt" ]; then
    mkdir -p ~/.wt
fi

if [ "$action" = "add" ]; then
    echo "domain:$domain, webroot:$webroot, nginx_conf_path:$nginx_conf_path"
    if [ ! -d "$webroot" ]; then
        mkdir -p $webroot
    fi

    \cp -rf index.html $webroot

    if [ ! -d "$nginx_conf_path" ]; then
        echo "invalid nginx config path"
    fi

    # 生成默认的http nginx 配置，确保 certonly模式网络能访问，当然这个前提是已经把域名的dns配置好了
    ## 构建http网络环境
    ## 使用 sed 命令将文件 a 中的 BBB 替换为 domain 的值，将 AAA 替换为 webroot 的值，并将结果输出到 domain.conf 文件
    sed "s|BBB|$domain|g; s|AAA|$webroot|g" default-http.conf > $domain.conf

    mv $domain.conf $nginx_conf_path
    nginx -s reload 

    ## 开始生成https证书
    # 执行certbot命令
    certbot certonly --webroot -w $webroot -d $domain |grep .pem > ~/.wt/$domain

    ## 分别获取fullchain.pem 和 privkey.pem
    full_pem_path=$(cat ~/.wt/$domain|head -n 1)
    private_pem_path=$(sed -n '2p' ~/.wt/$domain)
    echo "letsencrypt pem path:$full_pem_path, $private_pem_path"
    ## 到这里我们已经成功获取letsencrypt的https证书了，接下来就是生成最终的nginx conf 文件
    sed "s|BBB|$domain|g; s|AAA|$webroot|g; s|CCC|$full_pem_path|g; s|DDD|$private_pem_path|g" default-https.conf > $domain.conf

    mv $domain.conf $nginx_conf_path
    nginx -s reload 
elif [ "$action" = "remove"  ]; then
    pem_path=$(cat ~/.wt/$domain|head -n 1)
    echo "letsencrypt pem path :$pem_path"
    yes Y | certbot revoke --force-interactive --cert-path $pem_path
    rm -f ~/.wt/$domain
    nginx -s reload 
fi
