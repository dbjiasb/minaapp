import os
import subprocess
import sys
from pathlib import Path

# 动态获取项目根目录（当前脚本所在目录）
PROJECT_ROOT = Path(__file__).parent.absolute()

# 子脚本路径配置
SCRIPTS = [
    os.path.join(PROJECT_ROOT, 'string_category.py'),
    os.path.join(PROJECT_ROOT, 'create_var.py'),
    os.path.join(PROJECT_ROOT, 'replace_strings.py')
]

def run_script(script_path):
    """执行单个Python脚本并返回结果状态"""
    if not os.path.exists(script_path):
        print(f"错误: 脚本 {script_path} 不存在")
        return False

    print(f"正在执行: {os.path.basename(script_path)}")
    result = subprocess.run(
        [sys.executable, script_path],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )

    # 输出脚本执行结果
    if result.stdout:
        print(f"输出:\n{result.stdout[:500]}...")  # 限制显示长度
    if result.stderr:
        print(f"错误信息:\n{result.stderr}")

    return result.returncode == 0

if __name__ == '__main__':
    print(f"项目根目录: {PROJECT_ROOT}")
    print(f"脚本执行顺序: {[os.path.basename(s) for s in SCRIPTS]}\n")

    # 依次执行脚本
    for script in SCRIPTS:
        if not run_script(script):
            print(f"脚本 {os.path.basename(script)} 执行失败，终止流程")
            sys.exit(1)

    print("\n所有脚本执行完成！")