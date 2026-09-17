# DeepSeek Harness — عربي

## ما هذا؟
حاوية Docker لـ DeepSeek Harness بواجهة عربية، مبنية على النسخة الرسمية
من deepseek-ai/deepseek-harness مع دعم اللغة العربية عبر
آلية language-pack المدمجة.

## الحالة الحالية
- ✅ البناء يعمل (Docker)
- ✅ الحاوية تعمل + healthy
- ✅ الاتصال بـ Ollama host يعمل
- ✅ إثبات مفهوم العربية: 4 namespaces (20 مفتاحاً)
- ⏳ التعريب الكامل: 41 namespace (~1268 مفتاحاً) — قيد العمل
  (common namespace: عندنا ترجمة سابقة جاهزة - ستُدمج قريباً)

## المعمارية
- **Dockerfile:** multi-stage (builder: node:24, runtime: node:24-slim)
- **المنفذ:** 3081 على المضيف → 3080 داخل الحاوية
- **Ollama:** host.docker.internal:11434/v1
- **DSH_HOME:** volume دائم (settings + sessions)

## آلية التعريب
DSH يدعم إضافة لغات عبر language-pack API:
  ctx.locale.addLanguage({ id: 'ar', label: 'العربية', fallback: 'en' })
  ctx.locale.register(ns, 'ar', dict)
لا تُعدّل الحزم — فقط plugin المركزي (packages/client/locale).
القواميس العربية في ملف واحد: locales/ar.ts

## البناء
  docker compose build
  docker compose up -d

## التشغيل
افتح: `http://127.0.0.1:3081/?token=`<TOKEN من logs>

## المراجع
- المستودع الرسمي: https://github.com/deepseek-ai/deepseek-harness
- الإصدار: 0.1.6-alpha.1
- الـ commit: 0d1f50007f
