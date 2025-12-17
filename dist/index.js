import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { generateDiaryRequestSchema } from './validator';
import { generateWithRules } from './generator';
dotenv.config();
const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(cors({ origin: process.env.ALLOW_ORIGIN || '*' }));
// 健康探针
app.get('/health', (req, res) => {
    res.json({ ok: true, ts: Date.now() });
});
// 核心接口
app.post('/api/diary/generate', async (req, res, next) => {
    try {
        const parsed = generateDiaryRequestSchema.safeParse(req.body);
        if (!parsed.success) {
            const msg = parsed.error.issues.map(i => `${i.path.join('.')}: ${i.message}`).join('; ');
            const error = { error: { code: 'BadRequest', message: msg, retryable: false } };
            res.status(400).json(error);
            return;
        }
        const input = parsed.data;
        // 真实 AI 生成的占位：目前用规则生成；后续在这里替换为模型调用
        const result = await generateWithRules(input);
        res.status(200).json(result);
    }
    catch (e) {
        const msg = typeof e === 'object' ? JSON.stringify(e) : String(e);
        const error = { error: { code: 'ServerError', message: msg, retryable: true } };
        res.status(500).json(error);
    }
});
const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
    console.log(`DayLoom backend listening on http://localhost:${port}`);
});
