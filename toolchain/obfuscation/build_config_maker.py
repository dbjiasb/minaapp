import os
import json
import re
import datetime


def normalize_string(s):
    """标准化字符串：移除下划线并转为小写"""
    return s.replace('_', '').lower()

def convert_to_pascal_case(s):
    """将蛇形命名转换为帕斯卡命名（首字母大写的驼峰命名）"""
    words = s.split('_')
    return ''.join(word.capitalize() for word in words)


def extract_classes_from_dart(file_path):
    """从Dart文件中提取类名"""
    classes = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        # 匹配类定义的正则表达式，支持abstract和final修饰符
        pattern = re.compile(r'^\s*(?:abstract\s+)?(?:final\s+)?(?:interface\s+)?class\s+(\w+)\s*', re.MULTILINE)
        matches = pattern.findall(content)
        classes.extend(matches)
    except Exception as e:
        print(f"处理文件时出错 {file_path}: {e}")
    return classes


def get_main_class(filename, classes):
    """根据文件名和类列表确定主类"""
    if not classes:
        raise ValueError(f"文件 {filename} 中未找到任何类定义")

    # 提取文件名（不含扩展名）并标准化
    base_name = os.path.splitext(filename)[0]
    normalized_filename = normalize_string(base_name)

    # 查找与文件名匹配的类（忽略大小写和下划线）
    for cls in classes:
        normalized_class = normalize_string(cls)
        if normalized_class == normalized_filename:
            return cls

    # 若无匹配，返回第一个类
    return classes[0]


def process_directory(config_dir, modules_path):
    """处理包含build_config.json的目录"""
    # 获取当前文件夹名称（作为分类依据）
    current_folder = os.path.basename(config_dir)
    interface_file = None
    implement_files = []

    # 递归扫描所有Dart文件
    for root, _, files in os.walk(config_dir):
        for file in files:
            if file.lower().endswith('.dart'):
                dart_file_path = os.path.join(root, file)
                # 获取相对于modules目录的完整相对路径
                relative_path = os.path.relpath(dart_file_path, modules_path)
                # 提取文件名（不含扩展名）
                filename = os.path.basename(dart_file_path)
                file_base = os.path.splitext(filename)[0]
                print('filename is ' + filename)
                # 提取类名
                classes = extract_classes_from_dart(dart_file_path)
                try:
                    main_class = get_main_class(filename, classes)
                    file_info = {
                        'path': relative_path,
                        'filename': filename,
                        'classes': classes,
                        'class': main_class
                    }

                    # 判断是否为接口文件（文件名与文件夹名相同）
                    if file_base.lower() == f"{current_folder.lower()}_interface":
                        interface_file = file_info
                    else:
                        implement_files.append(file_info)

                except ValueError as e:
                    print(f"错误: {e} - {dart_file_path}")

    # 验证接口文件是否存在
    if not interface_file:
        print(f"警告: 未找到与文件夹同名的接口文件 - {current_folder}")

    # 确定输出路径并读取现有配置
    output_path = os.path.join(config_dir, 'build_config.json')
    existing_data = {}
    if os.path.exists(output_path):
        try:
            with open(output_path, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
        except json.JSONDecodeError:
            print(f"警告：现有build_config.json文件格式错误，将创建新文件。")

    # 生成输出数据
    output_data = {
        'interface_file': interface_file,
        'implement_files': implement_files,
        'generated_at': datetime.datetime.now().isoformat()
    }
    # 检查并添加pick字段（从现有配置继承或新建）
    if 'pick' in existing_data:
        output_data['pick'] = existing_data['pick']
    elif implement_files:
        output_data['pick'] = implement_files[0]
    
    # 生成env字段
    if interface_file and 'pick' in output_data:
        interface_class = interface_file.get('class')
        implement_class = output_data['pick'].get('class')
        if interface_class and implement_class:
            output_data['env'] = f'--dart-define={interface_class}={implement_class}'
        else:
            print(f"警告：无法生成env字段，interface_class或implement_class为空")
    else:
        print(f"警告：无法生成env字段，缺少interface_file或pick字段")

    # 写入build_config.json
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    print(f"已生成配置文件: {output_path}")


def has_configurable_class(directory):
    folder_name = os.path.basename(directory)
    # 构建接口文件路径 {folder_name}_interface.dart
    interface_file_name = f"{folder_name}_interface.dart"
    dart_file_path = os.path.join(directory, interface_file_name)
    
    # 检查接口文件是否存在
    if not os.path.exists(dart_file_path):
        return False
    
    print(f"检查接口文件: {dart_file_path}")
    try:
        with open(dart_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # 查找所有abstract interface class定义
        for i, line in enumerate(lines):
            stripped_line = line.strip()
            # 匹配abstract interface class开头的类定义
            if re.match(r'^abstract\s+interface\s+class\s+', stripped_line):
                # 检查上一行是否包含//configurable
                if i > 0 and '//@configurable' in lines[i-1].strip():
                    return True
        return False
    except Exception as e:
        print(f"检查配置类时出错: {e}")
        return False

def main():
    # 确定modules目录路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    modules_path = os.path.abspath(os.path.join(script_dir, '..', 'modules'))

    if not os.path.isdir(modules_path):
        print(f"错误: 模块目录不存在 - {modules_path}")
        return

    # 遍历modules目录下的所有子目录
    for root, _, files in os.walk(modules_path):
        if has_configurable_class(root):
            print(f"正在处理目录: {root}")
            process_directory(root, modules_path)


if __name__ == '__main__':
    main()