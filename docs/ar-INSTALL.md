# دليل التثبيت والإعداد — DSH-Arabic

> هذه نسخة fork غير رسمية من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
> (التوثيق الكامل بالعربية يبدأ من [README.ar.md](../README.ar.md)).

## ما سيتوفر بعد التثبيت

| العنصر | قيمة |
|--------|--------|
| حاوية | `dsh-web` |
| الواجهة | `http://127.0.0.1:3080` (على الجهاز نفسه) |
| الـ volume | `dsh_home` (يدوم عبر إعادة البناء) |
| الإعدادات | `settings.yaml` مبذور مسبقًا بثلاث نماذج Ollama |

## متطلبات المضيف

المضيف **لا يحتاج Node.js ولا pnpm** — كل ذلك داخل الصورة.

| المتطلب | التوضيح |
|---------|---------|
| Docker Engine + Docker Compose | الأمر الرئيسي `docker compose up` |
| Ollama (اختياري) | إن أردت استخدام النماذج محليًا — راجع [ar-CONFIGURATION.md](ar-CONFIGURATION.md) |
| نظام التشغيل | مُختَبَر على Linux فقط |

## التثبيت عبر Docker (المسار الموصى به)

### 1) احصل على الكود
```bash
git clone https://github.com/naifmalharthi/deepseek-harness
cd deepseek-harness
```

### 2) ابنِ وشغّل
```bash
docker compose up -d --build
```
البناء الأول يتحمّل الحزم ويُجمّع الواجهة — قد يستغرق دقائق حسب الشبكة.

### 3) استخرج التوكن
```bash
docker logs dsh-web 2>&1 | grep -oE 'token=[A-Za-z0-9_-]+' | head -1
```

### 4) افتح الواجهة
```
http://127.0.0.1:3080/?token=<token>
```
> ⚠️ يجب أن يكون الفتح من الجهاز نفسه (عنوان `127.0.0.1`).
> راجع [ar-TROUBLESHOOTING.md](ar-TROUBLESHOOTING.md) — القسم الأول

## التهيئة عند أول تشغيل

عند أول إقلاع، `docker/entrypoint.sh` يقوم بالآتي:
1. إنشاء `/home/node/.dsh` إن لم يوجد.
2. **يبذر** `settings.yaml` بثلاث نماذج Ollama — **فقط إن كان الملف غير موجود**؛ لا يلمس موجودًا أبدًا.
3. يسلم التحكم للخادم عبر الأمر: `pnpm dsh --profile web --patch …/dsh-web.docker.patch.yml --no-open`.

لذا أول تشغيل يعطيك فورًا: نماذج جاهزة + لغة تُختار من الواجهة (الإعدادات ← اللغة ← العربية).

**للتحقق أن كل شيء حيّ:**
```bash
docker ps --filter name=dsh-web --format '{{.Names}}: {{.Status}}'
# المنتظر: dsh-web: Up (healthy)
```

## التثبيت من المصدر (لأغراض التطوير فقط)

> مسار غير موصى به للاستخدام اليومي — يُنصح باستخدام Docker.
> يتطلب Node.js `^22.19 ‖ >=24` وأداة `pnpm`.

```bash
git clone https://github.com/naifmalharthi/deepseek-harness
cd deepseek-harness
pnpm install
pnpm run build
pnpm dsh --profile web
```
(المسار في Docker: `pnpm dsh --profile web --patch …/dsh-web.docker.patch.yml --no-open` —
انظر `Dockerfile` السطر 44. قيود الـ loopback نفسها سارية.)

## التحقق السريع بعد أي تثبيت

| الفحص | الأمر |
|-------|-------|
| الحالة | `docker compose ps` |
| التوكن | `docker logs dsh-web --tail 20` |
| الشبكة | `docker network inspect deepseek-harness_default --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'` |
| الـ volume | `docker volume ls \| grep dsh` |
| الإعدادات | `docker exec dsh-web cat /home/node/.dsh/settings.yaml` |

## الخطوات التالية

- إعدادات تفصيلية: [ar-CONFIGURATION.md](ar-CONFIGURATION.md)
- عند أي مشكلة: [ar-TROUBLESHOOTING.md](ar-TROUBLESHOOTING.md)
- كيف يعمل داخليًا: [ar-ARCHITECTURE.md](ar-ARCHITECTURE.md)

---
*Fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (MIT).*
