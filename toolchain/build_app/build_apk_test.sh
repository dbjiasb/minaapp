#!/bin/bash -l

echo " ------------- Build APK Test --------------------"

export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
build_dir=$(pwd)

  # 检查当前目录路径是否包含 'roll'
if [[ "$build_dir" == *"roll"* ]]; then
    alias flutter='/Users/roll/Roll/Library/flutter3.29/bin/flutter'
    echo "Use flutter from /Users/roll/Roll/Library/flutter3.29/bin/flutter"
else
    echo "Use flutter from system."
fi

flutter --version

app_path=$build_dir'/../../debug'
exportFilePath=$app_path'/build/app/outputs/flutter-apk/app-release.apk'
package_desc='内测包'

# YAML操作
file_path=$app_path'/pubspec.yaml'

version_and_build=$(python3 -c "import yaml; print(yaml.safe_load(open('$file_path'))['version'])")
version=$(echo $version_and_build | cut -d "+" -f1)
build=$(echo $version_and_build | cut -d "+" -f2)
build=$(($build+1))

python3 $build_dir/modify_build_ver.py $file_path $build


file_name=$version'.'$build'_'$(date +%s)'.apk'

cd $app_path
current_branch=$(git symbolic-ref --short HEAD)
echo "Current branch is: $current_branch"

flutter clean
flutter pub get
flutter build apk --release --dart-define=buildType=debug --no-tree-shake-icons

# 上传APK
file_url=$(python3 $build_dir/upload_2_cos.py $file_name $exportFilePath '/test')
echo 'result: '$file_url

# 生成二维码
#python3 $build_dir/app_qrcode.py $file_url

#发送飞书
size=`du -m $exportFilePath | awk '{print $1}'`
sh $build_dir/webhook_feishu.sh $file_url $version'.'$build "$size" $package_desc

##删除二维码
rm -rf qrcode.png
#删除包
rm -rf exportFilePath