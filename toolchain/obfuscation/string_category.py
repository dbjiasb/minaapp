import json
import re
from pathlib import Path
import argparse

def extract_dart_strings():

    # 新路径配置
    root_dir = Path(__file__).parent.parent.parent / "biz"
    
    # 添加路径验证
    if not root_dir.exists():
        raise FileNotFoundError(f"Modules目录未找到: {root_dir}")
    unique_strings = set()
    excluded_files = {"security.dart", "apis.dart", "copywriting.dart", "decrypt.dart", "routes.dart", "other.dart"}
    
    # 优化后的正则表达式（移除三引号匹配，简化匹配逻辑）
    string_pattern = re.compile(
        r'''r?(["'])((?:\\\1|.)*?)\1''',
        re.DOTALL
    )
    
    # 新增API请求正则表达式
    api_request_pattern = re.compile(
        r'ApiRequest\(\s*([\'"])(.*?)\1',
        re.DOTALL
    )
    
    for file_path in root_dir.rglob("*.dart"):
        if file_path.name in excluded_files:
            continue
        
        with open(file_path, "r", encoding="utf-8") as f:
            # 新增注释行过滤逻辑
            content_lines = []
            for line in f:
                stripped_line = line.lstrip()  # 移除行首空白
                if not stripped_line.startswith('//'):  # 过滤以//开头的行
                    content_lines.append(line)
            content = ''.join(content_lines)
            
            filtered_content = re.sub(r'debugPrint\(.*?\);', '', content)
            matches = string_pattern.findall(filtered_content)
    
            # 新增API请求扫描
            api_matches = api_request_pattern.findall(content)
            for quote, api_str in api_matches:
                stripped_api = api_str.strip()
                if len(stripped_api) > 0:
                    unique_strings.add((file_path, '', stripped_api))  # 特殊标记API字符串

            if matches:
                # 修改字符串收集逻辑，添加文件路径信息
                for _, (quote, text) in enumerate(matches, 1):  
                    stripped = text.rstrip('\n')
                    if len(stripped) > 1 \
                        and not stripped.isspace() \
                        and not (text.lstrip().startswith(('package:', 'import')) or
                                stripped.startswith('../')) \
                        and not ('$' in stripped) \
                        and not (stripped.startswith('dart') or
                                stripped.endswith('.dart')):
                            unique_strings.add((file_path, quote, stripped))  # 存储文件路径信息

    # 删除原有的文件初始化操作
    category_map = {
        'assets': set(),
        'copywriting': set(),
        'links': set(),
        'routes': set(),
        'apis': set(),
        'security': set(),
        'other': set()
    }

    # 在最终分类部分添加变量名正则匹配
    dart_var_pattern = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')  # 新增变量名匹配规则
    # 收集所有API字符串
    api_strings = {s for _, quote, s in unique_strings if quote == ''}

    # 处理其他字符串（排除API字符串）
    # 修改分类逻辑
    for file_path, quote, s in sorted(unique_strings):
        if quote == '':
            continue
        if s in api_strings:
            category_map['apis'].add(s)
            continue
        if s.startswith("packages") or s.lower().endswith(('.png', '.webp')):
            category_map['assets'].add(s)
        elif s[0].isupper() and (' ' in s or s.endswith('...')):
            category_map['copywriting'].add(s)
        elif '://' in s:
            category_map['links'].add(s)
        elif s.startswith('/') and file_path.name == 'router_names.dart':
            # 添加文件名判断条件
            category_map['routes'].add(s)
        else:
            if dart_var_pattern.match(s):
                category_map['security'].add(s)
            else:
                category_map['other'].add(s)

    # 最终JSON输出
    output_dir = Path(__file__).parent
    with open(output_dir/'scan_result.json', 'w', encoding='utf-8') as f:
        json_data = {
            category: {
                'count': len(values),
                'items': sorted(list(values))
            } for category, values in category_map.items()
        }
        json.dump(json_data, f, indent=2, ensure_ascii=False)

    print("结果已保存至 scan_result.json")

if __name__ == "__main__":
    extract_dart_strings()