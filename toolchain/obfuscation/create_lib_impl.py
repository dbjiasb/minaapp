import os
import json
import re
from pathlib import Path

def process_modules_directory(root_dir):
    """递归遍历modules目录下所有文件夹，处理包含build_config.json的目录"""
    modules_path = os.path.join(root_dir, 'modules')
    if not os.path.exists(modules_path):
        print(f"Modules directory not found: {modules_path}")
        return

    for dirpath, _, filenames in os.walk(modules_path):
        if 'build_config.json' in filenames:
            process_build_config(dirpath)

def process_build_config(dir_path):
    """处理单个build_config.json文件"""
    config_path = os.path.join(dir_path, 'build_config.json')
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error loading {config_path}: {e}")
        return

    # 提取必要配置信息
    interface_file = config.get('interface_file', {})
    pick_info = config.get('pick', {})
    interface_class = interface_file.get('class')
    pick_class = pick_info.get('class')
    interface_filename = interface_file.get('filename')
    pick_filename = pick_info.get('filename')  # 添加获取pick的filename

    if not all([interface_class, pick_class, interface_filename, pick_filename]):  # 增加pick_filename检查
        print(f"Missing required fields in {config_path}")
        return

    # 生成Dart类文件
    dart_class_name, dart_file_name = generate_class_info(interface_class)
    dart_file_path = os.path.join(dir_path, dart_file_name)
    is_new_created = create_dart_class(dart_file_path, dart_class_name, interface_class, pick_class, interface_filename, pick_filename)  # 传递新参数

    # 实现抽象方法
    interface_file_path = os.path.join(dir_path, interface_filename)
    if os.path.exists(interface_file_path):
        methods = extract_abstract_methods(interface_file_path, interface_class)
        if methods:
            append_methods_to_class(dart_file_path, dart_class_name, methods, is_new_created)
    else:
        print(f"Interface file not found: {interface_file_path}")

def generate_class_info(interface_class):
    """根据接口类名生成Dart类名和文件名"""
    # 移除开头的'I'
    if interface_class.startswith('I'):
        dart_class_name = interface_class[1:]
    else:
        dart_class_name = interface_class

    # 转换为蛇形命名作为文件名
    snake_case = re.sub(r'(?<!^)(?=[A-Z])', '_', dart_class_name).lower()
    dart_file_name = f"{snake_case}.dart"
    return dart_class_name, dart_file_name

def create_dart_class(file_path, class_name, interface_class, pick_class, interface_filename, pick_filename):
    """创建Dart类文件并添加静态_adapter变量"""
    # 确保目录存在
    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    # 检查文件是否存在
    if os.path.exists(file_path):
        # 文件存在，读取内容并替换_adapter声明
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 添加导入检查
        import_pattern = re.compile(rf'^import\s+[\'\"]{re.escape(pick_filename)}[\'\"];\n', re.MULTILINE)
        if not import_pattern.search(content):
            content = content.replace(
                '\nclass', 
                f'import \'{pick_filename}\';\n\nclass', 
                1
            )
        # 定义正则表达式匹配_adapter声明
        adapter_pattern = re.compile(r'static\s+final\s+\w+\s+_adapter\s*=\s*\w+\(\)\s*;')
        new_adapter_line = f'static final {interface_class} _adapter = {pick_class}();'
        updated_content = adapter_pattern.sub(new_adapter_line, content)

        # 写回修改后的内容
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        print(f"Updated {file_path}")
        return False
    else:
        # 文件不存在，创建新文件
        content = f"""import '{interface_filename}';
import '{pick_filename}';

class {class_name} {{
  static final {interface_class} _adapter = {pick_class}();

}}
"""

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Created {file_path}")
        return True

def extract_abstract_methods(file_path, class_name):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 采用花括号计数法匹配类边界
    class_pattern = re.compile(rf'abstract\s+interface\s+class\s+{re.escape(class_name)}\s*{{')
    match = class_pattern.search(content)
    if not match:
        return []

    # 找到类定义的起始位置
    start_pos = match.end()
    brace_count = 1
    end_pos = start_pos
    
    # 遍历字符直到花括号平衡
    while end_pos < len(content) and brace_count > 0:
        if content[end_pos] == '{':
            brace_count += 1
        elif content[end_pos] == '}':
            brace_count -= 1
        end_pos += 1

    class_content = content[start_pos:end_pos-1]

    # 增强方法匹配模式（支持泛型、可空类型和命名参数）
    method_pattern = re.compile(
        r'((?:@[\w\d]+\s+)*)'  # 注解
        r'([\w<>\[\],?\s]+)\s+'  # 返回类型
        r'(\w+)\s*'  # 方法名
        r'\(([^)]*)\)\s*;',  # 参数列表
        re.DOTALL
    )
    
    methods = []
    for match in method_pattern.finditer(class_content):
        # 清理参数中的多余空格和换行
        params = re.sub(r'\s+', ' ', match.group(4).replace('\n', ' ').strip())
        methods.append({
            'return_type': match.group(2).strip(),
            'name': match.group(3).strip(),
            'params': params
        })

    return methods

def append_methods_to_class(file_path, class_name, methods, is_new_file):
    """将实现的方法追加到Dart类（新增is_new_file参数控制）"""
    if not is_new_file:
        return
    if not os.path.exists(file_path):
        print(f"Class file not found: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 找到类的结束括号前的位置
    end_brace_index = None
    for i, line in reversed(list(enumerate(lines))):
        if '}' in line and not line.strip().startswith('//'):
            end_brace_index = i
            break

    if end_brace_index is None:
        print(f"Could not find class end brace in {file_path}")
        return

    # 生成方法实现
    method_lines = []
    for method in methods:
        ret_type = method['return_type']
        name = method['name']
        params = method['params']
        # 检测命名参数
        has_named_params = params.strip().startswith('{') and params.strip().endswith('}')
        # 从原始参数解析参数名称
        param_list = [p.strip() for p in method['params'].replace('{', '').replace('}', '').split(',') if p.strip()]
        param_names = [
            re.sub(r'^.*?([a-zA-Z_][a-zA-Z0-9_]*)\s*$', r'\1', param.split('=')[0].strip()).strip() 
            for param in param_list
        ]
        param_vars = [f'{name}: {name}' if has_named_params else name for name in param_names]
        
        if ret_type == 'void':
            method_impl = f'  static void {name}({params}) {{\n    _adapter.{name}({", ".join(param_vars)});\n  }}'
        else:
            method_impl = f'  static {ret_type} {name}({params}) {{\n    return _adapter.{name}({", ".join(param_vars)});\n  }}'
        method_lines.append(method_impl)

    # 插入方法到类中
    new_lines = lines[:end_brace_index] + [f"\n{line}\n" for line in method_lines] + lines[end_brace_index:]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print(f"Updated {file_path} with {len(methods)} methods")

if __name__ == '__main__':
    # 获取项目根目录（假设脚本位于toolchain目录，项目根目录为上级目录）
    script_path = os.path.abspath(__file__)
    root_dir = os.path.dirname(os.path.dirname(script_path))
    process_modules_directory(root_dir)