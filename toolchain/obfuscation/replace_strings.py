import argparse
import re
import shutil
from pathlib import Path
import json

# 白名单配置（新增）
REPLACE_CONFIG = {
    'security': {
        'pattern': r"(['\"])({})\1",
        'replacement': 'Security.security_{}',
        'import': 'security'
    },
    'apis': {
        'pattern': r"(ApiRequest\()\s*['\"]({})['\"]\s*(?=,|\s*\))",
        'replacement': r'\1Apis.security_{}',
        'import': 'apis'
    },
    'copywriting': {
        'pattern': r"(['\"])({})\1",
        'replacement': 'Copywriting.security_{}',
        'import': 'copywriting'
    },
    'routes': {
        'pattern': r"(['\"])({})\1",
        'replacement': 'Routes.security_{}',
        'import': 'routes'
    },
    'images': {
        'pattern': r"(['\"])({})\1",
        'replacement': 'Images.security_{}',
        'import': 'images'
    },
    'other': {
        'pattern': r"(['\"])({})\1",
        'replacement': 'Other.security_{}',
        'import': 'other'
    }
}

def clean_string(s: str) -> str:
    cleaned = re.sub(r'[^a-zA-Z0-9_]', '_', s.strip())
    cleaned = re.sub(r'^\d+', '', cleaned)
    if not cleaned:
        return ''
    return cleaned

def replace_security_strings(enable_backup=False):
    script_dir = Path(__file__).parent

    # 读取JSON文件
    input_file = script_dir / 'scan_result.json'
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 构建正则表达式模式，每条规则携带对应的导入语句
    patterns = []

    for key in ['security', 'apis', 'copywriting', 'routes', 'images']:  # 白名单控制
        config = REPLACE_CONFIG[key]
        items = data[key]['items']
        import_stmt = f"import 'package:biz/base/crypt/{config['import']}.dart';"

        for s in sorted(items, key=lambda x: -len(x)):
            patterns.append((
                re.compile(config['pattern'].format(re.escape(s))),
                config['replacement'].format(clean_string(s)),
                import_stmt
            ))

    # 配置工程目录（根据实际项目结构调整）
    project_dir = Path(__file__).parent.parent.parent / "biz"
    total_replacements = 0

    # 需要排除的文件列表
    excluded_files = {'security.dart', 'apis.dart', 'copywriting.dart', 'routes.dart', 'other.dart', 'images.dart'}

    # 遍历所有Dart文件
    for dart_file in project_dir.rglob('*.dart'):
        # 跳过需要忽略的文件
        if dart_file.name in excluded_files:
            continue

        content = dart_file.read_text(encoding='utf-8')
        file_replacements = 0
        needed_imports = set()

        # 执行所有替换规则，记录实际触发的导入
        for pattern, replacement, import_stmt in patterns:
            content, count = pattern.subn(replacement, content)
            file_replacements += count
            if count > 0:
                needed_imports.add(import_stmt)

        # 按需插入对应的导入语句，避免重复
        for stmt in needed_imports:
            if stmt not in content:
                content = stmt + '\n' + content

        if file_replacements > 0:
            # 仅在启用备份时创建备份
            if enable_backup:
                backup_path = dart_file.with_suffix(f'{dart_file.suffix}.bak')
                if not backup_path.exists():
                    shutil.copy2(dart_file, backup_path)

            # 写入修改后的内容（无论是否备份都执行）
            dart_file.write_text(content, encoding='utf-8')
            print(f'✅ 已更新 {dart_file} ({file_replacements} 处替换)')
            total_replacements += file_replacements

    print(f'\n替换完成！共在 {total_replacements} 处完成替换')
    print('安全提示：请检查所有.bak备份文件后手动删除')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--backup', action='store_true',
                       help='启用文件备份功能（生成.bak文件）')
    args = parser.parse_args()

    replace_security_strings(args.backup)
