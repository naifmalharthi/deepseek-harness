# المساهمة — DSH-Arabic (fork)

> [README-AR.md](README-AR.md) هي بوابة الدخول. هذا الملف يخص **هذا الـ fork فقط**.

## ما يقبله هذا الـ fork

| النوع | أمثلة | الحالة |
|-------|-------|--------|
| توثيق عربي | إصلاحات، إضافات، ترجمات `docs/ar-*.md` | ✓ مقبول |
| تحسين Docker | `Dockerfile`, `docker-compose.yml`, `docker/` | ✓ مقبول |
| تعريب القوائم | `packages/client/locale/src/locales/ar/` | ✓ مقبول |
| تعديلات في كود الأصل | `packages/core/*`, `apps/*`, ... | ✗ يُوجَّه للأصل (انظر أدناه) |

## كيف تساهم (التوثيق والترجمة)

1. أنشئ فرعًا: `git checkout -b fix/ar-<theme>`
2. عدّل الملف/الملفات (نفس القواعد المستعملة في `docs/ar-*`):
   - لا تخترع معلومات — اقرأ الكود/الملفات الفعلية أولًا
   - العربية الفصحى المبسطة؛ الأوامر بالإنجليزية
   - الروابط النسبية الصحيحة دائمًا
3. ارفع وطبع PR إلى هذا المستودع (ليس الأصل)

> القاعدة الذهبية: كل حقيقة في وثيقة لها **منزل واحد**. إن وجدت معلومة مكررة،
> اتركها في منزلها الأصلي واربطها.

## قواعد الـ commit

```
docs(ar):    توثيق عربي         مثال: docs(ar): add Arabic INSTALL guide
fix(docker): إصلاح Docker     مثال: fix(docker): pin pnpm version
feat(locale): تعريب            مثال: feat(locale): add "sidebar" namespace (12 keys)
chore:       أعمال صيانة
```

(نفس نمط `type(scope): description` المستخدم في الأصل.)

## ماذا تفعل إذا كان إصلاحك يخص الأصل؟

المشروع الأصل **لا يقبل pull requests حاليًا** (انظر [CONTRIBUTING.md](CONTRIBUTING.md)). الخيارات:

1. [GitHub Discussions](https://github.com/deepseek-ai/deepseek-harness/discussions)
   (الإبلاغ عن المشكلة/النقاش)
2. إضافة وسم [`dsh-plugin`](https://github.com/topics/dsh-plugin) لوصلتك
3. [Discord](https://discord.gg/Ycq5dCaS4)

## الترخيص

كل ما تضيفه يخضع لـ [LICENSE](LICENSE) (MIT، DeepSeek 2026) —
لا تنسَ الإشارة في commit إذا كان لكودك ترخيص مختلف.

---
*Fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).*
