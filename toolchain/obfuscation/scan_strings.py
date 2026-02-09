import re
from pathlib import Path
import argparse

def extract_dart_strings(deduplicate=True):  # 修改默认值为True
    root_dir = Path("pods/modules")
    unique_strings = set()
    excluded_files = {"constants.dart", "es_helper.dart"}  # 新增排除文件列表
    
    # 优化后的正则表达式（移除三引号匹配，简化匹配逻辑）
    string_pattern = re.compile(
        r'''r?(["'])((?:\\\1|.)*?)\1''',
        re.DOTALL
    )

    for file_path in root_dir.rglob("*.dart"):
        if file_path.name in excluded_files:  # 新增过滤条件
            continue
        
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            filtered_content = re.sub(r'debugPrint\(.*?\);', '', content)
            matches = string_pattern.findall(filtered_content)

            if matches:
                if not deduplicate:  # 非去重模式保留文件头打印
                    print(f"\n📁 {file_path}")
                for i, (quote, text) in enumerate(matches, 1):
                    stripped = text.strip()
                    if len(stripped) > 1 \
                       and not stripped.isspace() \
                       and not (text.lstrip().startswith(('package:', 'import')) or
                               stripped.startswith(('../'))) \
                       and not ('$' in stripped) \
                       and not (stripped.startswith('dart') or
                               stripped.endswith('.dart')):
                        if deduplicate:
                            unique_strings.add(stripped)  # 去重模式存入集合
                        else:
                            print(f"🅇 [{i}] {quote}{text}{quote}")  # 原输出逻辑
    
    if deduplicate:  # 去重模式统一输出
        for s in sorted(unique_strings):
            print(s)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # 修改参数为关闭去重模式
    parser.add_argument('-n', '--no-deduplicate', 
                        action='store_false', 
                        dest='deduplicate',
                        default=True,
                        help='禁用去重模式')
    args = parser.parse_args()
    
    with open('scan_strings_result.txt', 'w', encoding='utf-8') as output_file:
        import sys
        original_stdout = sys.stdout
        sys.stdout = output_file

        try:
            extract_dart_strings(args.deduplicate)  # 参数逻辑已反转
        finally:
            sys.stdout = original_stdout

    print("结果已保存至 scan_strings_result.txt")