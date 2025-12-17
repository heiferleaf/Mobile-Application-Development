## 后端运行说明

通过npm install后，根据运行的模块缺失结果补全依赖，最后通过`npm run dev`即可运行后端，开放给前端访问端口

> 由于AI调用涉及到密钥，所以过滤.env环境变量配置文件
> .env文件内容格式如下
```
PORT=3000
ALLOW_ORIGIN=*
OPENAI_API_KEY= 此处替换为真实可用的密钥
OPENAI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
OPENAI_MODEL=qwen-plus
```
