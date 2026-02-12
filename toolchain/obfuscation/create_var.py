import re
import base64
from pathlib import Path
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
import argparse
import json

# 修正为32字节的密钥（数下面这行字符正好32个）
KEY = b'CDhvMci5g7ExnCT885TqT7LT9S9I2A5l'  # 32字符（32字节）
# 修正IV为16字节（数下面字符正好16个）
IV = b'xm7uIbAfnoq8TxCJ'  # 16字节（注意去掉最后的g）

def encrypt_string(plaintext: str) -> str:
    cipher = AES.new(KEY, AES.MODE_CBC, IV)
    padded_data = pad(plaintext.encode('utf-8'), AES.block_size)
    ciphertext = cipher.encrypt(padded_data)
    return base64.b64encode(ciphertext).decode('utf-8')

def generate_security_constants(prefix='security'):
    script_dir = Path(__file__).parent
    # 新增目标目录定义
    target_dir = script_dir.parent.parent / 'biz/lib/base/crypt'
    target_dir.mkdir(parents=True, exist_ok=True)
    input_file = script_dir / 'scan_result.json'
    
    if not input_file.exists():
        print(f"错误：未找到输入文件 {input_file.absolute()}")
        return

    try:
        import json
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            variables_data = data.get('security', {}).get('items', [])
            
            # 获取variables分类的字符串列表
            lines = [item for item in variables_data]
    except json.JSONDecodeError:
        print(f"错误：{input_file} 不是有效的JSON文件")
        return
    except Exception as e:
        print(f"读取JSON文件失败: {str(e)}")
        return

    # 白名单配置（新增）
    allowed_keys = ['security', 'apis', 'copywriting', 'routes']
    target_classes = {
        'security': ('Security', 'security'),  # (类名, 文件名)
        'apis': ('Apis', 'apis'),
        'copywriting': ('Copywriting', 'copywriting'),
        'routes': ('Routes', 'routes'),
        'other': ('Other', 'other')
    }

    # 处理白名单中的每个分类（修改）
    for category in allowed_keys:
        category_data = data.get(category, {}).get('items', [])
        valid_vars = []
        seen = set()
        
        # 修改后的循环逻辑
        for original_var in category_data:
            # 字符替换处理
            cleaned = re.sub(r'[^a-zA-Z0-9_]', '_', original_var.strip())
            cleaned = re.sub(r'^\d+', '', cleaned)
            if not cleaned:
                continue
            cleaned = cleaned[0].lower() + cleaned[1:]
            
            if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', cleaned) and cleaned not in seen:
                seen.add(cleaned)
                valid_vars.append((cleaned, encrypt_string(original_var), original_var))  # 存储原始值

        if not valid_vars:
            continue

        # 动态生成文件路径（修改）
        output_file = target_dir / f'{target_classes[category][1]}.dart'
        class_name = target_classes[category][0]
        # Initialize header content for new files
        header_content = [
            "import 'decrypt.dart';",
            "",
            f"abstract final class {class_name} {{\n"
            f"  {class_name}._();"
        ]
        # 文件存在处理逻辑（保持原有逻辑）
        existing_vars = set()
        if output_file.exists():
            # 读取现有内容并找到最后一个右括号
            existing_content = output_file.read_text(encoding='utf-8').splitlines()
            # 查找最后一个右括号的行
            closing_brace_index = None
            for i in reversed(range(len(existing_content))):
                line = existing_content[i]
                stripped = line.strip()
                if stripped == '}':
                    closing_brace_index = i
                    break
            # 确定header_content
            if closing_brace_index is not None:
                header_content = existing_content[:closing_brace_index]
            else:
                print("警告：未找到闭合的右括号，可能导致生成的文件格式错误")
            
            # 解析现有变量
            existing_vars = set(re.findall(r'static late final String (\w+) = decrypt', '\n'.join(existing_content)))  # 修改正则表达式
            
            # 新增过滤逻辑
            # 修改后的过滤逻辑
            valid_vars = [
                (v, e, o) 
                for v, e, o in valid_vars 
                if f'{prefix}_{v}' not in existing_vars
            ]
        else:
            valid_vars = valid_vars  # 新文件无需过滤

        # 移除生成new_vars时的重复过滤条件
        new_vars = [
            f'  static late final String {prefix}_{v} = decrypt(\'{e}\'); // {o}'
            for v, e, o in valid_vars
        ]
        # 写入文件（保持原有逻辑）
        dart_code = header_content + new_vars + ['}']
        output_file.write_text('\n'.join(dart_code), encoding='utf-8')
        print(f"生成成功：{output_file.absolute()}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--prefix', default='security', 
                       help='变量名前缀，默认为security')
    args = parser.parse_args()
    
    generate_security_constants(args.prefix)