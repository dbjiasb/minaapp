#!/usr/bin/python

import os
import sys

from qcloud_cos import CosConfig
from qcloud_cos import CosS3Client

# 配置 COS 参数
sid = 'IKID5nBG0mkOihLedOTGq62dusVnrbz3m9Bu'   # 替换为自己的 SecretId
skey = 'TcRve3DFxKM6XdDUT9UVBVYHhoaFbdLj'   # 替换为自己的 SecretKey
region = 'na-ashburn'    # 替换为自己的地区信息
bucket = 'overseas-gime-1370751292'     # 替换为自己的 Bucket 名称

config = CosConfig(Region=region, SecretId=sid, SecretKey=skey)
client = CosS3Client(config)

def upload_file(local_path, cos_path):
    response = client.upload_file(
        Bucket=bucket,
        LocalFilePath=local_path,
        Key=cos_path
    )
    location = response["Location"]
#     print('Upload file success!, location:'+location)
    return location

args = sys.argv[1:] # 去除脚本名称作为索引0的位置
# for arg in args:
#     print('参数：'+arg)
file_name = args[0]   # 在COS中保存的目标路径及文件名
local_path = args[1]     # 要上传的本地文件路径
sub_group = args[2]
cos_path = 'app/android' + sub_group + '/' + file_name   # 在COS中保存的目标路径及文件名
result = upload_file(local_path, cos_path)
cdn_path = 'https://cdn.imagime.co/' + cos_path
print(cdn_path)

