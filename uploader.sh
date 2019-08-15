#!/bin/bash

# -----------------------------------------------------
# 名称：KindleEar安装脚本
# 作者：bookfere.com
# 页面：https://bookfere.com/post/19.html
# 更新：2019.08.15
# -----------------------------------------------------

divid_1="=================================="
divid_2="----------------------------------"

cd ~ && clear

echo "准备上传 KindleEar"
echo $divid_1

if [ ! -d "./KindleEar" ]; then
    echo "开始拉取 KindleEar 源代码"
    git clone https://github.com/cdhigh/KindleEar.git
else
    response="y"
    read -r -p "检测到已存在 KindleEar 源码，是否更新？[y/N] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [[ ! -d "./KindleEar/.git" ]]; then
            mv -f ./KindleEar/config.py ./KindleEar/app.yaml ./KindleEar/module-worker.yaml .
            rm -rf ./KindleEar && git clone https://github.com/cdhigh/KindleEar.git
            mv -f ./config.py ./app.yaml ./module-worker.yaml ./KindleEar
        else
            cd ./KindleEar && git pull && cd ..
        fi
    fi
fi
cd KindleEar


cemail=$(sed -n "s/^SRC_EMAIL\ =\ \"\(.*\)\".*#.*/\1/p" ./config.py)
cappid=$(sed -n "s/^DOMAIN\ =\ \"http\(\|s\):\/\/\(.*\)\.appspot\.com\/\".*#.*/\2/p" ./config.py)

echo $divid_1
echo "当前的 Gmail 为："$cemail
echo "当前的 APPID 为："$cappid

response="y"
if [ ! $cemail = "akindleear@gmail.com" -o ! $cappid = "kindleear" ]; then
    echo $divid_2
    read -r -p "是否修改 APP 必要配置? [y/N] " response
fi

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo $divid_2
    read -r -p "请输入你的 Gmail 地址：" email
    sed -i "s/^SRC_EMAIL = \".*\"/SRC_EMAIL = \"$email\"/g" ./config.py
    read -r -p "请输入你的 APP ID：" appid
    sed -i "s/^application: .*/application: $appid/g" ./app.yaml ./module-worker.yaml
    sed -i "s/^DOMAIN = \"http\(\|s\):\/\/.*\.appspot\.com\/\"/DOMAIN = \"http:\/\/$appid\.appspot\.com\/\"/g" ./config.py
fi
echo $divid_1


response="N"
read -r -p "是否修改其它相关配置？[y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo $divid_2
    parameters=(
        "COLOR_TO_GRAY"
        "GENERATE_TOC_THUMBNAIL"
        "GENERATE_TOC_DESC"
        "GENERATE_HTML_TOC"
        "PINYIN_FILENAME"
        # more...
    )
    descriptions=(
        "是否将图片转换为灰度？"
        "是否为目录生成缩略图？"
        "是否为目录添加摘要？"
        "是否生成HTML格式目录？"
        "是否将中文名转为拼音？"
        # more...
    )
    index=0
    for parameter in ${parameters[@]}; do
        old_value=$(sed -n "s/^$parameter\ =\ \(.*\)/\1/p" ./config.py)
        notice="否"; if [[ $old_value = "True" ]]; then notice="是"; fi
        response="N"
        read -r -p ${descriptions[index]}"当前（${notice}）[y/N] " response
        if [[ $response ]]; then
            new_value="False"
            if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then new_value="True"; fi
            sed -i "s/^$parameter = $old_value/$parameter = $new_value/g" ./config.py
        fi
        let index+=1
    done
fi
echo $divid_1


read -r -p "准备完毕，是否确认上传 [y/N] " response
echo $divid_2
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "正在上传，请稍候……"
    appcfg.py update app.yaml module-worker.yaml --no_cookie --noauth_local_webserver
    appcfg.py update . --no_cookie --noauth_local_webserver
    echo "KindleEar 已上传完毕"
else
    echo "已放弃上传"
fi
echo $divid_1