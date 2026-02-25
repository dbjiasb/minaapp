
# 项目目录（默认为当前目录）
PROJECT_DIR="$(pwd)"
PLIST_PATH="${PROJECT_DIR}/ExportOptions.plist"
TEAM_ID="X39WY82PUD"

# 导出选项配置
cat > ${PLIST_PATH} << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
       <key>com.qikun.minaai</key>
       <string>Xcode Managed Profile</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution: qikun tan (X39WY82PUD)</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>X39WY82PUD</string>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

yaml_path=$PROJECT_DIR'/pubspec.yaml'
echo 'yaml: '$yaml_path
version_and_build=$(python3 -c "import yaml; print(yaml.safe_load(open('$yaml_path'))['version'])")
version=$(echo $version_and_build | cut -d "+" -f1)
echo 'version: '$version

flutter --version
flutter clean
flutter packages get

cd ios


#pod update
pod install || exit 1
echo "--->更新依赖库结束"

pwd

cd ../

echo "--->开始编译"
flutter build ipa -v --release --obfuscate --split-debug-info=symbols/${version} --export-options-plist=${PLIST_PATH}
echo "--->编译完毕"

BUILD_IOS_PATH=${PROJECT_DIR}/build/ios
ARCHIVE_PATh=${BUILD_IOS_PATH}/archive/Runner.xcarchive
IPA_PATH=${BUILD_IOS_PATH}/ipa/release.ipa

echo "ipa: ${IPA_PATH}"
echo "--->上传至appstore️"
xcrun altool --upload-app -f "${IPA_PATH}" -u "15112181155@139.com" -p "ytca-lrgr-afyv-gfkc" --type ios || exit
echo "--->上传完毕"
