#!/bin/bash -l

echo " ------------- Build iOS Test --------------------"

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

IPA_NAME="Soulink"
APP_NAME="Runner"
CONFIGURATION="Release"
upload_script=$build_dir'/pgyer_upload.sh'
app_path=$build_dir'/../../debug'
WORKSPACE_PATH=${app_path}/ios/${APP_NAME}.xcworkspace
EXPORT_OPTIONS=${app_path}/ios/ExportOptionsDev.plist
ArchivePath=${app_path}/build/ios/runner.xcarchiverunner.xcarchive
exportFilePath=${app_path}/build/ios/release-ipa

# YAML操作
file_path=$app_path'/pubspec.yaml'

version_and_build=$(python3 -c "import yaml; print(yaml.safe_load(open('$file_path'))['version'])")
version=$(echo $version_and_build | cut -d "+" -f1)
build=$(echo $version_and_build | cut -d "+" -f2)
build=$(($build+1))

python3 $build_dir/modify_build_ver.py $file_path $build

cd $app_path
current_branch=$(git symbolic-ref --short HEAD)
echo "Current branch is: $current_branch"

flutter clean
flutter pub get

echo "------------------------------------flutter build ------------------------------------------"
flutter build ios --release --dart-define=buildType=debug --no-tree-shake-icons

echo "---------------------------------------xcodebuild archive ---------------------------------"
xcodebuild archive -workspace ${WORKSPACE_PATH} -scheme ${APP_NAME} -configuration ${CONFIGURATION} -sdk iphoneos -archivePath ${ArchivePath}

echo "---------------------------------------xcodebuild export ---------------------------------"
xcodebuild -exportArchive -archivePath $ArchivePath -exportPath $exportFilePath -exportOptionsPlist $EXPORT_OPTIONS -allowProvisioningUpdates -quiet || exit


desc=`git log --pretty=format:"%s(via %an,%ad)\n" --date=format:"%m-%d %H:%M:%S" -n 5`
echo $desc
AK="0146a6039322c9ec0658873c8b45bbf2"

echo "---------------------------------------upload ---------------------------------"
IPA_PATH=${exportFilePath}/${IPA_NAME}'.ipa'
echo "IPA_PATH: $IPA_PATH"
sh $upload_script -k ${AK} -d "内测包（${current_branch}）\n${desc}" $IPA_PATH
#rm -rf ${ArchivePath}
#rm -rf $IPA_PATH

