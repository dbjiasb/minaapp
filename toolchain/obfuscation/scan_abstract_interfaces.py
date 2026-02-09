import os
import re

def scan_abstract_interface_methods(directory):
    # 匹配抽象接口类定义的正则表达式
    class_pattern = re.compile(
        r'^\s*abstract\s+interface\s+class\s+(\w+)(\s*<.*>)?\s*\{',
        re.MULTILINE
    )
    
    # 修复：增强方法匹配正则表达式，支持命名参数和多种方法声明格式
    method_pattern = re.compile(
        r'^\s*([\w\s<>,?]+\s+\w+\s*\([^)]*\)\s*;)',
        re.MULTILINE
    )
    
    # 遍历目录下所有Dart文件
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                
                # 读取文件内容
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 查找所有抽象接口类
                for class_match in class_pattern.finditer(content):
                    class_start = class_match.start()
                    class_name = class_match.group(1)
                    
                    # 查找类结束的花括号（修复：使用更精确的匹配）
                    brace_count = 1
                    class_end = class_start
                    while class_end < len(content) and brace_count > 0:
                        if content[class_end] == '{':
                            brace_count += 1
                        elif content[class_end] == '}':
                            brace_count -= 1
                        class_end += 1
                    
                    # 提取类内容并查找方法声明
                    class_content = content[class_start:class_end]
                    methods = method_pattern.findall(class_content)
                    
                    # 打印所有找到的方法
                    for method in methods:
                        print(method.strip())

if __name__ == "__main__":
    # 项目根目录路径
    project_directory = '/Users/wei/workspace/soulink/soulinkapp/'
    scan_abstract_interface_methods(project_directory)