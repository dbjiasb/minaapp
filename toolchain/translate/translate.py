#!/usr/bin/python

from gpt import chat_gpt

text_group_path = '../../internal_package/lib/localize/lib'
en_text_path = text_group_path + '/localize_strings_en.dart'

# 写入文件
def write_to_file(text, file_name, append):
    with open(file_name, 'a' if append else 'w') as file:
        file.write(text)

lang_to_chinese = {
'zh-CN' : '中文',
'es' : '西班牙语',
'de' : '德语',
'fr' : '法语',
'it' : '意大利语',
'pt' : '葡萄牙语',
'ru' : '俄语',
'pt' : '葡萄牙语',
'ja' : '日语',
'ko' : '韩语',
'ar' : '阿拉伯语'
}

def translate_text_to_lang(text, langInChinese):
    prompt = text + '\n这里是一份App界面文案，帮我将上述文本中\':\'后面的字符翻译成' + langInChinese + ', 请不要删除其他字符任何字符'
    print('prompt：' + prompt)
    translate_result = chat_gpt(prompt)
    return translate_result


def translate_to_lang(lang, loc):

    des_text_path = text_group_path + '/localize_strings_'+ loc.lower() + '.dart'

    # 打开文件并读取其中的文本内容
    with open(en_text_path, 'r') as file:
        lines = file.readlines()

    total_count = len(lines)

    # 读取前三行替换写入
    header_lines = lines[0 : 3]
    header_text = ''.join(header_lines)
    header_text = header_text.replace('LocalizeStringsEN', 'LocalizeStrings' + loc, 1)
    header_text = header_text.replace('en_US', lang + '_' + loc, 1)
    write_to_file(header_text, des_text_path, False)

    prompt = ''
    lines_one_time = 200
    read_count = 0
    content_lines = lines[3 : total_count - 3]
    content_len = len(content_lines)

    while content_len > read_count:
        write_to_file('\t\t\t', des_text_path, True)

        # 获取分段文本
        left_count = content_len - read_count
        next_count = lines_one_time if left_count > lines_one_time else left_count
        endIndex = read_count + next_count
        cur_arr = content_lines[read_count : endIndex]
        cur_text = ''.join(cur_arr)
        print('翻译前：' + cur_text)

        lang_in_chinese = lang_to_chinese[lang]
        translate_result = translate_text_to_lang(cur_text, lang_in_chinese)
        print('翻译后：' + translate_result)

        # 写文件
        write_to_file(translate_result, des_text_path, True)
        write_to_file('\n', des_text_path, True)
        read_count += next_count


    # 读取后三行替换写入
    header_lines = lines[total_count - 3 : total_count]
    header_text = ''.join(header_lines)
    write_to_file(header_text, des_text_path, True)

# 调用
# translate_to_lang('zh-CN', 'CN')
# translate_to_lang('es', 'ES')
# translate_to_lang('de', 'DE')
# translate_to_lang('it', 'IT')
# translate_to_lang('fr', 'FR')
# translate_to_lang('pt', 'PT')
# translate_to_lang('ru', 'RU')
# translate_to_lang('ja', 'JP')
# translate_to_lang('ko', 'KR')
translate_to_lang('ar', 'AE')
# txt = translate_text_to_lang('\"log_in_account\" : \"Log in your account\",\"enter_confirmation_code\" : \"Enter confirmation code\"', '中文，西班牙语，德语，意大利语，法语，葡萄牙语，俄语，日语，韩语，阿拉伯语')
# print(txt)