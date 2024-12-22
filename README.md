# httpswebtool
wt(webtool)脚本工具是一个基于certbot快速部署管理https网站的脚本小工具

## https 网站部署
很多时候我们经常部署一些https落地页面或者网站，一般我们的都是通过certbot的letsencrypt搞定，这需要一些步骤，虽然不复杂，但是还是要费时的。这个项目目的就是一键搞定https证书的申请和nginx的配置部署。

## 项目现状
1. 这个项目的第一个阶段就是先围绕certbot来做一些脚本自动化，后面会丰富交互和扩展其他工具支持，比如泛域名的支持等，先做一些基本的自动化
2. 假设已经安装了certbot
3. 假设用的是nginx
4. 用的是root，没有权限问题

## 命令格式
wt.sh [action] [domain]  [webroot]  [nginx-config-path]

- action: add | remove, add是添加域名和网站，remove是撤销和销毁tls证书
- domain: 是要部署的域名，一般都是子域名
- webroot：nginx 下对应的网站根目录
- nginx-config-path：nginx的conf文件的目录，我们会自动创建[domain].conf格式的conf文件，并重启nginx，使其生效

## 注意
1. 创建时，会生成nginx域名根目录，tls证书和nginx conf配置文件
2. 删除时，只是撤销和删除了证书，但是nginx根目录和配置不动，请根据需要进一步手动删除
