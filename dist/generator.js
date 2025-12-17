import OpenAI from 'openai';
// 使用 DashScope 的 OpenAI 兼容端点（或其他 OpenAI 兼容服务）
const client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    baseURL: process.env.OPENAI_BASE_URL
});
export async function generateWithAI(req) {
    const start = Date.now();
    const prompt = buildPrompt(req);
    const system = `
你是一个日记生成助手。根据用户当天的记录和配置，严格输出 JSON，不要输出其他文本：
{
  "date": "YYYY-MM-DD",
  "title": "string",
  "sections": [{"name":"string","text":"string"}],
  "content": "string",
  "tags": ["string", ...],
  "images": [{"recordId":"string","sectionIndex":0,"caption":"string","anchorText":"string"}],
  "promptEcho": "string"
}
约束：
- images[].recordId 必须来自当天 records 里 type="image" 的 id；
- sectionIndex 必须在 sections 的范围内；
- anchorText 必须是对应 section 的 text 中出现的词（若无则省略）。
`;
    const model = process.env.OPENAI_MODEL || 'qwen-plus';
    const completion = await client.chat.completions.create({
        model,
        temperature: 0.7,
        messages: [
            { role: 'system', content: system },
            { role: 'user', content: prompt }
        ]
    });
    const text = completion.choices?.[0]?.message?.content ?? '';
    let diary;
    try {
        diary = JSON.parse(text);
    }
    catch {
        // 兜底：AI 输出非 JSON 时走规则生成
        return await generateWithRules(req, Date.now() - start, model, 'BadJSON');
    }
    if (!diary || !Array.isArray(diary.sections)) {
        return await generateWithRules(req, Date.now() - start, model, 'BadShape');
    }
    // 基础健壮性：修正越界的 sectionIndex、非法 recordId
    diary.images = sanitizeImages(diary.images, diary.sections, req);
    const metrics = {
        model,
        latencyMs: Date.now() - start
    };
    return { diary, metrics };
}
// 规则生成兜底：保证服务稳定返回
export async function generateWithRules(req, elapsed, modelName, reason) {
    const start = Date.now();
    const textRecords = req.records.filter(r => r.type === 'text');
    const imageRecords = req.records.filter(r => r.type === 'image');
    const title = textRecords.length > 0 ? trimTitle(textRecords[0].content) : '今日小记';
    // 段落：按 contentBlocks 的顺序选择文本；若无文本，提供默认文案
    const sections = [];
    for (let i = 0; i < req.options.contentBlocks.length; i++) {
        const b = req.options.contentBlocks[i];
        if (!b.enabled)
            continue;
        const t = pickText(textRecords, i);
        sections.push({ name: b.name, text: t });
    }
    if (sections.length === 0) {
        sections.push({ name: '今日', text: summarizeText(textRecords) });
    }
    const content = summarizeText(textRecords);
    // 标签：启用的样式名称或简单关键词
    const tags = req.options.diaryStyles.filter(s => s.enabled).slice(0, 5).map(s => s.name);
    // 图片：均匀分配到段落，尝试根据段落文本找 anchorText
    const images = [];
    for (let j = 0; j < imageRecords.length; j++) {
        const img = imageRecords[j];
        const secIdx = j % Math.max(1, sections.length);
        const anchor = findAnchorIn(sections[secIdx].text);
        images.push({
            recordId: img.id,
            sectionIndex: secIdx,
            caption: buildCaption(img.content),
            anchorText: anchor
        });
    }
    // 健壮性修正
    const fixedImages = sanitizeImages(images, sections, req);
    const diary = {
        date: req.date,
        title,
        sections,
        content,
        tags,
        images: fixedImages,
        promptEcho: buildPromptEcho(req) + (reason ? ` | fallback=${reason}` : '')
    };
    const metrics = {
        model: modelName || (process.env.MODEL_NAME || 'mock-gpt'),
        latencyMs: elapsed ?? (Date.now() - start)
    };
    return { diary, metrics };
}
// ------------------ 辅助函数 ------------------
function buildPrompt(req) {
    const blocks = req.options.contentBlocks.filter(b => b.enabled).map(b => b.name).join('、') || '今日';
    const styles = req.options.diaryStyles.filter(s => s.enabled).map(s => s.name).join('、') || '朴素';
    const texts = req.records.filter(r => r.type === 'text').map(r => `- ${r.time}: ${safe(r.content)}`).join('\n');
    const images = req.records.filter(r => r.type === 'image').map(r => `- ${r.id}: ${safe(r.content)}`).join('\n');
    return [
        `日期: ${req.date}`,
        `内容块: ${blocks}`,
        `风格: ${styles}`,
        `标题显示: ${req.options.outputOptions.showTitles ? '是' : '否'}`,
        req.options.customInstructions ? `自定义指令: ${req.options.customInstructions}` : '',
        '文本记录：',
        texts || '(无)',
        '图片记录（用于 images.recordId）：',
        images || '(无)'
    ].join('\n');
}
function trimTitle(s) {
    const t = s.trim();
    if (t.length === 0)
        return '今日小记';
    return t.length > 24 ? t.slice(0, 24) : t;
}
function pickText(texts, i) {
    if (texts.length === 0)
        return '今天过得很充实。';
    const idx = i % texts.length;
    const t = texts[idx].content ? texts[idx].content.trim() : '';
    return t.length > 0 ? t : '今天过得很充实。';
}
function summarizeText(texts) {
    if (texts.length === 0)
        return '今天较为平静，记录不多。';
    const joined = texts.map(t => t.content).join(' ');
    const s = joined.trim();
    return s.length > 160 ? s.slice(0, 160) + '…' : s;
}
function findAnchorIn(text) {
    const anchors = ['阳光', '午后', '傍晚', '朋友', '学习', '散步', '雨', '图书馆', '操场'];
    for (let i = 0; i < anchors.length; i++) {
        if (text.indexOf(anchors[i]) >= 0)
            return anchors[i];
    }
    return undefined;
}
function buildCaption(content) {
    const t = content.trim();
    return t.length > 0 ? t : '今日瞬间';
}
function buildPromptEcho(req) {
    return `blocks=${req.options.contentBlocks.length}, styles=${req.options.diaryStyles.length}, showTitles=${req.options.outputOptions.showTitles}`;
}
function sanitizeImages(images, sections, req) {
    if (!images || images.length === 0)
        return [];
    const imageIds = new Set(req.records.filter(r => r.type === 'image').map(r => r.id));
    const maxIdx = sections.length - 1;
    const out = [];
    for (let i = 0; i < images.length; i++) {
        const img = images[i];
        // 过滤无效 recordId
        if (!img || !imageIds.has(img.recordId))
            continue;
        // 修正越界的 sectionIndex
        const sectionIndex = img.sectionIndex < 0 ? 0 : (img.sectionIndex > maxIdx ? maxIdx : img.sectionIndex);
        // 确保 anchorText 出现在对应段落
        let anchorText = img.anchorText;
        const secText = sections[sectionIndex]?.text || '';
        if (anchorText && secText.indexOf(anchorText) < 0) {
            anchorText = undefined;
        }
        out.push({
            recordId: img.recordId,
            sectionIndex,
            caption: img.caption,
            anchorText
        });
    }
    return out;
}
function safe(s) {
    return (s || '').replace(/\s+/g, ' ').trim();
}
