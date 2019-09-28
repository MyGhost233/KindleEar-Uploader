#!/bin/bash

# -----------------------------------------------------
# 名称：KindleEar安装脚本
# 作者：bookfere.com
# 页面：https://bookfere.com/post/19.html
# 更新：2019.09.28
# -----------------------------------------------------

divid_1="=============================================="
divid_2="----------------------------------------------"

cd ~ && clear

echo $divid_1
echo "准备上传 KindleEar"
echo $divid_1


source_url="https://github.com/cdhigh/KindleEar.git"
if [[ $1 ]]; then source_url=$1; fi
source_path=./$(echo $source_url | sed 's/.*\/\(.*\)\.git/\1/')
config_py=$source_path/config.py
app_yaml=$source_path/app.yaml
module_worker_yaml=$source_path/module-worker.yaml
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


if [ ! -d $source_path ]; then
    echo "开始拉取 KindleEar 源代码"
    echo $divid_2
    echo "源代码来源：$source_url"
    git clone $source_url
else
    response="y"
    read -r -p "源代码已存在，是否重新拉取？[y/N] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo $divid_2
        echo "源代码来源：$source_url"
        bak_email=$(sed -n "s/^SRC_EMAIL\ =\ \"\(.*\)\".*#.*/\1/p" $config_py)
        bak_appid=$(sed -n "s/^DOMAIN\ =\ \"http\(\|s\):\/\/\(.*\)\.appspot\.com\/\".*#.*/\2/p" $config_py)

        for parameter in ${parameters[@]}; do
            eval $parameter=$(sed -n "s/^$parameter\ =\ \(.*\)/\1/p" $config_py)
        done

        rm -rf $source_path && git clone $source_url

        sed -i "s/^SRC_EMAIL\ =\ \".*\"/SRC_EMAIL\ =\ \"$bak_email\"/g" $config_py
        sed -i "s/^application: .*/application: $bak_appid/g" $app_yaml $module_worker_yaml
        sed -i "s/^DOMAIN\ =\ \"http\(\|s\):\/\/.*\.appspot\.com\/\"/DOMAIN\ =\ \"http:\/\/$bak_appid\.appspot\.com\/\"/g" $config_py

        for parameter in ${parameters[@]}; do
            eval sed -i "s/^$parameter\ =\ .*/$parameter\ =\ \$$parameter/g" $config_py
        done
    fi
fi


current_email=$(sed -n "s/^SRC_EMAIL\ =\ \"\(.*\)\".*#.*/\1/p" $config_py)
current_appid=$(sed -n "s/^DOMAIN\ =\ \"http\(\|s\):\/\/\(.*\)\.appspot\.com\/\".*#.*/\2/p" $config_py)

echo $divid_1
if [ $current_email = "akindleear@gmail.com" -o $current_appid = "kindleear" ]; then
    echo "请按提示修改必要的 APP 配置参数"
    echo $divid_2
fi
echo "当前的 Gmail 为："$current_email
echo "当前的 APPID 为："$current_appid

response="y"
if [ ! $current_email = "akindleear@gmail.com" -o ! $current_appid = "kindleear" ]; then
    echo $divid_2
    read -r -p "是否重新修改 APP 必要配置参数? [y/N] " response
fi

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo $divid_2
    read -r -p "请输入你的 Gmail 地址：" email
    sed -i "s/^SRC_EMAIL\ =\ \".*\"/SRC_EMAIL\ =\ \"$email\"/g" $config_py
    read -r -p "请输入你的 APP ID：" appid
    sed -i "s/^application:\ .*/application:\ $appid/g" $app_yaml $module_worker_yaml
    sed -i "s/^DOMAIN = \"http\(\|s\):\/\/.*\.appspot\.com\/\"/DOMAIN = \"http:\/\/$appid\.appspot\.com\/\"/g" $config_py
fi
echo $divid_1


response="N"
read -r -p "是否修改其它相关配置参数？[y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo $divid_2
    index=0
    for parameter in ${parameters[@]}; do
        old_value=$(sed -n "s/^$parameter\ =\ \(.*\)/\1/p" $config_py)
        notice="否"; if [[ $old_value = "True" ]]; then notice="是"; fi
        response="N"
        read -r -p ${descriptions[index]}"当前（${notice}）[y/N] " response
        if [[ $response ]]; then
            new_value="False"
            if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then new_value="True"; fi
            sed -i "s/^$parameter\ =\ $old_value/$parameter\ =\ $new_value/g" $config_py
        fi
        let index+=1
    done
fi
echo $divid_1


read -r -p "准备完毕，是否确认上传 [y/N] " response
echo $divid_2
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "正在上传，请稍候……"
    appcfg.py update $app_yaml $module_worker_yaml --no_cookie --noauth_local_webserver
    appcfg.py update $source_path --no_cookie --noauth_local_webserver
    echo "KindleEar 已上传完毕"
else
    echo "已放弃上传"
fi
echo $divid_1
