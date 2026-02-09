#!/usr/bin/python

from openai import OpenAI

akey = "sk-QyE3Yu7zASyQrzVh4GN8"+"T3BlbkFJJi6hadSJhJjohRNghCld"

client = OpenAI(
    api_key=akey,
)

def chat_gpt(prompt):
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content.strip()

# message = chat_gpt('你好，你叫什么名字？')
#
# print(message)
