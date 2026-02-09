import re
from pathlib import Path

def deobfuscate_file(file_path):
    # 修正后的正则表达式模式
    pattern = re.compile(
        r'static String get (\w+)\s*=>\s*\'([^\']*)\'\.replaceAll\(\s*\'([^\']*)\',\s*(\w+)\)\s*;'
    )
    
    with open(file_path, 'r+', encoding='utf-8') as file:
        content = file.read()
        modified = False
        
        def replace_match(match):
            nonlocal modified
            modified = True
            var_name = match.group(1)
            original_str = match.group(2)
            replace_str = match.group(3)
            return f"static String get {var_name} => '{original_str.replace(replace_str, '')}';"
        
        new_content = pattern.sub(replace_match, content)
        
        if modified:
            file.seek(0)
            file.write(new_content)
            file.truncate()
            print(f'已更新: {file_path}')
        else:
            print(f'未找到匹配项: {file_path}')

if __name__ == '__main__':
    target_file = Path(__file__).parent.parent / 'modules' / 'lib' / 'base' / 'crypt' / 'constants.dart'
    deobfuscate_file(target_file)