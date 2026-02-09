import platform
from gpt import chat_gpt


text_group_path = '../../internal_package/lib/localize/lib'
system = platform.system()

append_text = """
    "ai_unlock_video_msg": "AI Avatar Unlock video message",
"""

lang_to_chinese = {
    'cn': '中文',
    'es': '西班牙语',
    'de': '德语',
    'fr': '法语',
    'it': '意大利语',
    'pt': '葡萄牙语',
    'ru': '俄语',
    'jp': '日语',
    'kr': '韩语',
    'ae': '阿拉伯语'
}

# translate_to_lang('zh-CN', 'CN')
# translate_to_lang('es', 'ES')
# translate_to_lang('de', 'DE')
# translate_to_lang('it', 'IT')
# translate_to_lang('fr', 'FR')
# translate_to_lang('pt', 'PT')
# translate_to_lang('ru', 'RU')
# translate_to_lang('ja', 'JP')
# translate_to_lang('ko', 'KR')

def write_to_file(text, file_name, append):
    with open(file_name, 'a' if append else 'w') as file:
        file.write(text)


def translate_text_to_lang(text, langInChinese):
    prompt = text + '\n这里是一份App界面文案，帮我将上述文本中\':\'后面的字符翻译成' + langInChinese + ', 请不要删除其他字符任何字符'
    print('prompt：' + prompt)
    translate_result = chat_gpt(prompt)
    return translate_result

def translate_to_lang():
    for key, value in lang_to_chinese.items():
        des_text_path = text_group_path + '/localize_strings_' + key + '.dart'
        print(des_text_path, value)
        translate_result = translate_text_to_lang(append_text,value)
        translate_result = '\t\t\t' + translate_result
        print(translate_result)
        # 打开文件并读取其中的文本内容
        if any(language in des_text_path for language in ['cn', 'es', 'de', 'fr', 'it']):
            # 备用，windows有些文件编码会报错
            # encode = 'gbk'
            encode = 'utf-8'
        elif 'pt' in des_text_path:
            # encode = 'latin-1'
            encode = 'utf-8'
        else:
            encode = 'utf-8'
        with open(des_text_path, mode='r', encoding=encode) as file:
            lines = file.readlines()
        insert_index = max(0, len(lines) - 3)
        if system == 'Windows':
            lines.insert(insert_index, translate_result + '\n')
        else:
            lines.insert(insert_index, translate_result + '\n')
        # 将修改后的列表内容写回文件
        with open(des_text_path, 'w', encoding=encode) as file:
            file.writelines(lines)

translate_to_lang()