import { z } from 'zod';
// 用 zod 做请求体基本校验
export const generateDiaryRequestSchema = z.object({
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    records: z.array(z.object({
        id: z.string(),
        type: z.enum(['text', 'image', 'voice']),
        time: z.string(),
        content: z.string(),
        imageUrl: z.string().optional(),
        location: z.string().optional()
    })),
    options: z.object({
        contentBlocks: z.array(z.object({
            id: z.string(),
            name: z.string(),
            enabled: z.boolean(),
            order: z.number()
        })),
        diaryStyles: z.array(z.object({
            id: z.string(),
            name: z.string(),
            enabled: z.boolean(),
            order: z.number()
        })),
        outputOptions: z.object({
            length: z.enum(['short', 'medium', 'long']),
            showTitles: z.boolean()
        }),
        customInstructions: z.string().optional()
    }),
    mediaPolicy: z.object({
        includeImageContext: z.boolean(),
        uploadImages: z.boolean()
    })
});
