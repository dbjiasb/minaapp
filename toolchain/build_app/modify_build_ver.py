import sys
import re

file_path = sys.argv[1]
new_build_number = sys.argv[2]

def update_build_number(pubspec_path, new_build_number):
    # 读取原始文件内容
    with open(pubspec_path, 'r') as file:
        lines = file.readlines()

    # 更新version行的build号
    updated_lines = []
    for line in lines:
        # 使用正则表达式匹配version行
        match = re.match(r'^version: (.+)$', line.strip())
        if match:
            # 分割版本号和build号
            version_parts = match.group(1).split('+')
            base_version = version_parts[0]  # 基础版本号
            if len(version_parts) > 1:
                # 如果存在build号，则更新
                line = f"version: {base_version}+{new_build_number}\n"
            else:
                # 如果不存在build号，则添加
                line = f"version: {base_version}+{new_build_number}\n"
        updated_lines.append(line)

    # 写回更新后的内容
    with open(pubspec_path, 'w') as file:
        file.writelines(updated_lines)

update_build_number(file_path, new_build_number)