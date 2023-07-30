#! /bin/sh

# 获取到的文件路径
file_path=""
file_name=""
# 文件后缀名
file_extension="podspec"
# 文件夹路径，pwd表示当前文件夹
directory="$(pwd)"

# 参数1: 路径；参数2: 文件后缀名
function getFileAtDirectory(){
    for element in `ls $1`
    do
        dir_or_file=$1"/"$element
        # echo "$dir_or_file"
        if [ -d $dir_or_file ]
        then
            getFileAtDirectory $dir_or_file
        else
            file_extension=${dir_or_file##*.}
            if [[ $file_extension == $2 ]]; then
                echo "$dir_or_file 是 $2 文件"
                file_path=$dir_or_file
                file_name=$element
            fi
        fi
    done
}
getFileAtDirectory $directory $file_extension

# 定义pod文件名称
pod_file_name=${file_name}
#echo "name：${pod_file_name}"

# 查找 podspec 的版本
search_str="s.version"

# 读取podspec的版本
podspec_version=""

#定义了要读取文件的路径
my_file="${pod_file_name}"
lines=0
foundlines=0
while read my_line
do
#输出读到的每一行的结果
# echo $my_line
((lines++))

    # 查找到包含的内容，正则表达式获取以 ${search_str} 开头的内容
    result=$(echo ${my_line} | grep "^${search_str}")
    if [[ "$result" != "" ]]
    then
           echo "\n ${my_line} 包含 ${search_str}"
           foundlines=$lines
           #lines=$(cat $my_file | grep -n ${search_str} | awk -F ":" '{print $1}')

           # 分割字符串，是变量名称，不是变量的值; 前面的空格表示分割的字符，后面的空格不可省略
        array=(${result// / })
        # 数组长度
        count=${#array[@]}
        # 获取最后一个元素内容
        version=${array[count - 1]}
        # 去掉 '
        version=${version//\'/}

        podspec_version=$version
    #else
           # echo "\n ${my_line} 不包含 ${search_str}"
           break
    fi

done < $my_file

#echo "\n 第${foundlines}行找到了版本号:${podspec_version}"
pod_spec_name=${file_name}
pod_spec_version=${podspec_version}
tailNumber=${pod_spec_version##*.}
addVersion=$(($tailNumber+1))
lengthofall=${#pod_spec_version}
lengthotail=${#tailNumber}
restlength=lengthofall-lengthotail
preVersion=${pod_spec_version:0:${restlength}}
joinedVersion=$preVersion$addVersion
sed -i "" "s/"${podspec_version}"/"${joinedVersion}"/g" $my_file
echo "原版本号：${pod_spec_version}，新版本号：${joinedVersion}"

# 组装commit
function commitEven(){
    git status
    git add .
    git commit -m $1
    git pull -r
    git push origin master
}

commit="脚本发布新版本：${joinedVersion}"
commitEven "$commit"

# 打tag和push
start=$(date +%s)
git tag $joinedVersion
git push --tags
pod spec lint --verbose --allow-warnings
pod trunk push ${pod_file_name}.podspec --verbose --allow-warnings --use-libraries

pushRepoResult=$?
echo "发布结果：${pushRepoResult}"

end=$(date +%s)
seconds=60
spend=`expr $end - $start`
minutes=`expr $spend / $seconds`

# 终端命令字体颜色设置：https://www.cnblogs.com/lr-ting/archive/2013/02/28/2936792.html
if [ $pushRepoResult == 0 ]
then
    echo "\n\033[32m 发布新版本：${joinedVersion} 成功，花费时间 $minutes 分钟! \033[0m\n"
else
    echo "\n\033[31m 发布版本：${joinedVersion} 失败，花费时间 $minutes 分钟! \033[0m\n"
fi

open .
