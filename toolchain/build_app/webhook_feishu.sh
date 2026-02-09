#!/bin/bash

file_url="$1"
version=$2
apk_size=$3
test_or_dis=$4
#file_url="http://gime-1321495078.cos.na-ashburn.myqcloud.com/app/android/test/1.2.6.52_1710241054.apk"
#version="1.2.6.52"
#apk_size="100"
echo 'file:'$file_url
echo 'ver:'$version
echo 'test_or_dis:'$test_or_dis
current_branch=$(git symbolic-ref --short HEAD)
desc=$(printf "%s" $(git log --pretty=format:"%s（via:%an｜%ad）\n" --date=format:"%m-%d_%H:%M:%S" -n 5))

# 获取token
#response=$(curl -s POST 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal' \
#           -H 'content-type:application/json; charset=utf-8' \
#           -d '{
#             "app_id": "cli_a56e1b8726b8500d",
#             "app_secret": "KD6XCIpBMNiQHbs2xImCkbPJwDvsra0S"
#           }')
#echo $response
#tenant_access_token=$(echo $response | jq '.["tenant_access_token"]' | sed 's/"//g')
#echo $tenant_access_token
#
## 上传二维码
#header_auth="Authorization: Bearer $tenant_access_token"
#echo $header_auth
#img_rsp=$(curl --location --request POST 'https://open.feishu.cn/open-apis/im/v1/images' \
#--header "$header_auth" \
#--header 'Content-Type: multipart/form-data' \
#--form 'image_type="message"' \
#--form 'image=@"qrcode.png"')
#echo $img_rsp
#img_key=$(echo "$img_rsp" | jq '.["data"]["image_key"]')
#echo $img_key
#img_key="img_v3_028u_a8d5f596-c847-401b-b0d3-8f8a6547642g"

# 发送飞书
ver_text="应用名称：Soulink\n应用类型：Android\n版本信息：$test_or_dis(v$version)\n版本分支：$current_branch\n应用大小：$apk_size MB\n下载链接：$file_url\n更新日志：\n$desc"
echo $ver_text
content='{
	"msg_type": "post",
	"content": {
		"post": {
			"zh_cn": {
				"title": "Soulink版本更新通知",
				"content": [
          [{
             "tag": "text",
             "text": "'$ver_text'"
           },
					 {
							"tag": "a",
							"text": "下载\n",
							"href": "'$file_url'"
						}
					]
				]
			}
		}
	}
}'
echo $content
curl -X POST -H "Content-Type: application/json" -d "$content" "https://open.feishu.cn/open-apis/bot/v2/hook/571bd4a7-2acf-412f-b1ac-0bdc7d3b1ea2"
curl -X POST -H "Content-Type: application/json" -d "$content" "https://open.feishu.cn/open-apis/bot/v2/hook/3784b24d-3621-4a24-bf23-88382df45427"
