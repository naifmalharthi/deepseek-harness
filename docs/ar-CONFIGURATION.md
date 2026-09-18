# التكوين — DSH-Arabic

> جزء من التوثيق العربي لـ fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).
> نقطة البداية: [README.ar.md](../README.ar.md)

## أين تُحفظ الإعدادات؟

| العنصر | القيمة |
|--------|--------|
| المجلد | `$DSH_HOME` = `/home/node/.dsh` داخل الحاوية |
| الملف | `settings.yaml` |
| الـ volume | `dsh_home` (named) — يدوم عبر `docker compose down` وإعادة البناء |
| المسار على المضيف | `docker volume inspect dsh_home --format '{{.Mountpoint}}'` (إن أردت فتحه خارجيًا) |

> ⚠️ **لا تحذف `settings.yaml`** — الـ entrypoint يبذره فقط إن كان غائبًا،
> لكن حذفك يدويًا يعني فقدان أي نماذج أضفتها.

## الملف الكامل (مثال حقيقي)

هذا هو محتوى `settings.yaml` الفعلي بعد أول تشغيل:

```yaml
llm-pi-ai:
  providers:
    ollama:
      displayName: ollama
      api: openai-completions
      baseURL: http://host.docker.internal:11434/v1
      apiKeyEnv: OLLAMA_API_KEY
      models:
        - id: qwen3.8:27b
          name: qwen3.8:27b
        - id: edtorre/qwen3.6-hermes:latest
          name: Qwen3.6 Hermes
        - id: qwen3.6:35b
          name: qwen3.6:35b
agent-default-model:
  provider: ollama
  model: qwen3.8:27b
ui-onboarding:
  welcomeNoticeVersion: 2026-08-13.1
locale:
  preference: ar
```

## شرح المفاتيح

### `llm-pi-ai` — مزودو LLM

البلوك الذي يُعرّف **أين وكيف** يتحدث DSH إلى النماذج. المصدر:
`docs/config-catalog.md` (§ `@deepseek-ai/dsh-llm-pi-ai`).

- `providers` — قاموس: **مفتاح كل عنصر هو اسم الـ route** (مثل `ollama`)،
  وقيمته كائن `PiAiProviderProfile`:

| المفتاح | إجباري؟ | التوضيح |
|---------|---------|---------|
| `displayName` | اختياري | الاسم الظاهر في الواجهة |
| `api` | اختياري* | بروتوكول الـ API، مثل `openai-completions` |
| `baseURL` | اختياري* | عنوان الخدمة، مثل `http://host.docker.internal:11434/v1` |
| `apiKeyEnv` | اختياري | **اسم متغير بيئة** (لا تضع المفتاح نفسه هنا لتبقيه خارج الملف) |
| `models` | — | قائمة `{ id, name }` — الـ `id` هو ما يُرسَل للخادم، والـ `name` للتعرض في الواجهة |

> *اختياري في الـ schema، لكن عمليًا: بدون `api`/`baseURL` لا يستطيع DSH الوصول لأي خادم.

### `agent-default-model` — النموذج الافتراضي

| المفتاح | إجباري؟ | التوضيح |
|---------|---------|---------|
| `provider` | **نعم** | يجب أن يطابق مفتاحًا في `llm-pi-ai.providers` |
| `model` | **نعم** | يجب أن يطابق `id` واحدًا في `models` لذلك المزوّد |

### مفاتيح مُراقَبة عمليًا (غير مضمونة كـ schema)

`ui-onboarding` و`locale` يظهران في الملف الحي لكنهما **ليسا** موثقين في
`config-catalog.md` — أي أن DSH قد يضيف مفاتيح جديدة فيهما دون إنذار.
غيّره من الواجهة لضمان ثباته (الإعدادات ← اللغة).

## تعديل الإعدادات

### الطريقة الموصى بها: الواجهة
في `http://127.0.0.1:3080/?token=<token>` → تبويب الإعدادات → النماذج/اللغة.
تُكتب التغييرات إلى `settings.yaml` تلقائيًا.

### الطريقة اليدوية: من المضيف

تحرير الملف مباشرة داخل الحاوية (لا يحتاج sudo ولا معرفة مسار الـ volume):

```bash
docker exec -it dsh-web vi /home/node/.dsh/settings.yaml
```

```bash
# راجع أن الخادم قرأ التغيير (تجديد)
docker compose restart
```

## إضافة مزوّد جديد (مثال)

```yaml
llm-pi-ai:
  providers:
    ollama:
      # …(كما هو)
    openai:
      displayName: OpenAI
      api: openai-completions
      baseURL: https://api.openai.com/v1
      apiKeyEnv: OPENAI_API_KEY
      models:
        - id: gpt-4o-mini
          name: GPT-4o mini
```

ثم ضَع المفتاح كمتغير بيئة في `docker-compose.yml`:
```yaml
environment:
  OPENAI_API_KEY: ${OPENAI_API_KEY}
```
> ⚠️ لا تضع `api_key` حرفيًا في `settings.yaml` — استخدم `apiKeyEnv` دائمًا.

## متغيرات البيئة

المعرّفة في `docker-compose.yml`:

| المتغير | القيمة | الغرض |
|---------|--------|-------|
| `DSH_HOME` | `/home/node/.dsh` | جذر مجلد الإعدادات |
| `OLLAMA_API_KEY` | `ollama-local` (افتراضي) | أي قيمة غير فارغة تكفي — Ollama لا يتحقق منها، لكن DSH يتطلب وجودها |

## ماذا يحدث إن حذفت/عدّلت؟

| الإجراء | النتيجة |
|---------|---------|
| حذف `settings.yaml` | الـ entrypoint يبذره بثلاثة نماذج Ollama عند الإقلاع التالي |
| تغيير `baseURL` | يتطلّب `docker compose restart` لإعادة القراءة |
| تغيير `locale.preference` خارجيًا | غيّره من الواجهة لضمان ثباته |

## النسخ الاحتياطي والاستعادة

نسخة احتياطية:

```bash
docker run --rm -v dsh_home:/from -v "$PWD/dsh-backup-$(date +%Y%m%d):/to" alpine sh -c 'cp -av /from/. /to/'
```

الاستعادة:

```bash
docker compose down
docker run --rm -v dsh_home:/to -v "$PWD/dsh-backup-YYYYMMDD:/from" alpine sh -c 'cp -av /from/. /to/'
docker compose up -d
```

> ⚠️ **تنبيه:** النسخة تحتوي `.credentials.yaml` (مفاتيح API) — احفظها في مكان آمن ولا ترفعها إلى Git.

## الملفات المرتبطة

- [ar-INSTALL.md](ar-INSTALL.md) — كيف تهيئ كل شيء أول مرة
- [ar-TROUBLESHOOTING.md](ar-TROUBLESHOOTING.md) — "تعذّر فتح ملف الإعدادات"
- [ar-ARCHITECTURE.md](ar-ARCHITECTURE.md) — لماذا تعمل هذه الطريقة
- المرجع الأصلي: [`docs/config-catalog.md`](config-catalog.md)

---
*Fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (MIT).*
