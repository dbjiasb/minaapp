#!/bin/bash -l

echo " ------------- Build AAB Release --------------------"
#export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
alias flutter329='/Users/roll/Roll/Library/flutter3.29/bin/flutter'

flutter329 --version

app_path=$(pwd)

yaml_path=$app_path'/pubspec.yaml'
echo 'yaml: '$yaml_path
version_and_build=$(python3 -c "import yaml; print(yaml.safe_load(open('$yaml_path'))['version'])")
version=$(echo $version_and_build | cut -d "+" -f1)
sybol_path='./sybol_adr_'$version;
echo 'sybol: '$sybol_path

echo 'Start clean'
flutter329 clean
echo 'Start pub get'
flutter329 pub get -v
echo 'Finish pub get'
echo 'Start build ios release'
flutter329 build appbundle --release -v --obfuscate --split-debug-info=$sybol_path
