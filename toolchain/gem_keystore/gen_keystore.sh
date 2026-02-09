

#  - `-keystore`：指定生成的 keystore 文件名及路径，如 `my-release-key.jks`。
#  - `-keyalg`：指定密钥算法，通常为 `RSA`。
#  - `-keysize`：指定密钥大小，一般为 `2048` 位。
#  - `-validity`：指定密钥的有效天数，如 `10000` 天。
#  - `-alias`：为密钥设置一个别名，如 `my-key-alias`。

#密钥库口令123456
keytool -genkeypair -v -keystore soulink.jks -keyalg RSA -keysize 2048 -validity 10000 -alias soulink-alias

