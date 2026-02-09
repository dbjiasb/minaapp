import re
import os
import random
import string
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
import base64
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

# 文件路径配置
DECRYPT_PATH = '../modules/lib/base/crypt/decrypt.dart'
TARGET_FILES = [
    '../modules/lib/base/crypt/security.dart',
    '../modules/lib/base/crypt/apis.dart',
    '../modules/lib/base/crypt/copywriting.dart'
]

# 生成符合Dart端要求的随机密钥（32位字母数字）
def generate_random_key(length):
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))

# 从decrypt.dart提取当前密钥
def extract_current_key():
    with open(DECRYPT_PATH, 'r') as f:
        content = f.read()
    key_match = re.search(r'final _aesKey = Key\.fromUtf8\(["\'](.*?)["\']\)', content)
    iv_match = re.search(r'final _iv = IV\.fromUtf8\(["\'](.*?)["\']\)', content)
    return key_match.group(1), iv_match.group(1)

# AES-CBC解密实现（匹配Dart端逻辑）
def decrypt_string(encrypted_data, key, iv):
    cipher = AES.new(key.encode('utf-8'), AES.MODE_CBC, iv.encode('utf-8'))
    decrypted_padded = cipher.decrypt(base64.b64decode(encrypted_data))
    return unpad(decrypted_padded, AES.block_size).decode('utf-8')

# AES-CBC加密实现（匹配create_var.py逻辑）
def encrypt_string(plaintext, key, iv):
    cipher = AES.new(key.encode('utf-8'), AES.MODE_CBC, iv.encode('utf-8'))
    padded_data = pad(plaintext.encode('utf-8'), AES.block_size)
    ciphertext = cipher.encrypt(padded_data)
    return base64.b64encode(ciphertext).decode('utf-8')

# 更新目标文件中的加密字符串
def update_encrypted_strings(old_key, old_iv, new_key, new_iv):
    for file_path in TARGET_FILES:
        with open(file_path, 'r') as f:
            content = f.read()

        # 查找所有decrypt调用
        pattern = re.compile(r'decrypt\(\s*["\'](.*?)["\']\s*\)')
        matches = pattern.findall(content)

        # 解密后重新加密并替换
        for encrypted_str in matches:
            decrypted = decrypt_string(encrypted_str, old_key, old_iv)
            new_encrypted = encrypt_string(decrypted, new_key, new_iv)
            content = content.replace(f'decrypt(\'{encrypted_str}\')', f'decrypt(\'{new_encrypted}\')')
            content = content.replace(f'decrypt("{encrypted_str}")', f'decrypt("{new_encrypted}")')

        with open(file_path, 'w') as f:
            f.write(content)

# 更新decrypt.dart中的密钥
def update_decrypt_file(new_key, new_iv):
    with open(DECRYPT_PATH, 'r') as f:
        content = f.read()

    # 只替换密钥和IV，保留其他内容
    content = re.sub(r'(final _aesKey = Key\.fromUtf8\(["\']).*?(["\']\\))', f'\\1{new_key}\\2', content)
    content = re.sub(r'(final _iv = IV\.fromUtf8\(["\']).*?(["\']\\))', f'\\1{new_iv}\\2', content)

    with open(DECRYPT_PATH, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    # 提取当前密钥
    old_key, old_iv = extract_current_key()

    # 生成新密钥
    new_key = generate_random_key(32)
    new_iv = generate_random_key(16)

    # 更新加密字符串
    update_encrypted_strings(old_key, old_iv, new_key, new_iv)

    # 更新解密文件
    update_decrypt_file(new_key, new_iv)

    print(f'Successfully re-encrypted with new key: {new_key}')