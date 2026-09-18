# البنية — DSH-Arabic

> جزء من التوضيح العربي لـ fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).
> هذا ملف تعليمي قصير؛ المرجع التفصيلي هو [architecture.md](architecture.md) (بالإنجليزية)
> و[cordis-primer.md](cordis-primer.md).

## الصورة الكبيرة

```
المتصفح (متصفحك)
    │  HTTP + WebSocket (نفس المنفذ 3080)
    ▼
╔═ حاوية dsh-web ═══════════════════════════════════╗
║  pnpm dsh --profile web --patch …/dsh-web.docker.patch.yml --no-open
║                                                        │
║  Cordis  ← شجرة plugins متراكبة (profile + الحزم +     │
║            patches + إعداداتك)                         │
║   ┌──────────┬───────────┬──────────────┐             │
║   │ agent-loop│ llm-pi-ai │ ui-settings │  … كل جزء    │
║   │ (نواة)    │ (تكيفي)    │ (مرآة إعدادات) plugin     │
║   └──────────┴───────────┴──────────────┘             │
╚═══╤════════════════════════════╤══════════════════════╝
    │ (RPC عبر WS: settings.describe / write / …)
    ▼
volume dsh_home → /home/node/.dsh
    settings.yaml • الجلسات • بيانات التخزين

[Ollama على المضيف] ← host.docker.internal:11434/v1 ← llm-pi-ai
```

## Cordis: كل شيء plugin

من [architecture.md](architecture.md) (قسم Cordis):

> لا يوجد "نواة" لها صلاحيات مطلقة تُصلَّح — كل شيء (تكيفي النموذج، أدوات، سجل الجلسات،
> حلقة الـ agent نفسها) هو **plugin** يساهم بخدمات وأحداث ومؤثرات قابلة للانعكاس
> في سياق مشترك، وقابلة للاستبدال من التكوين.

هذا ما يفسر لماذا التعريب في هذا الـ fork كان ممكنًا بلا كسر:
حزمة `locale` تسجّل القواميس في السياق نفسه الذي يسجّل فيه أي plugin خدماته.

## profiles والحزم

| المفهوم | التعريف (من [architecture.md §Profiles and bundles](architecture.md#profiles-and-bundles)) |
|---------|--------|
| **profile** | تركيب مُسمّى محفوظ في Harness home؛ يحدد الحزم التي يراكمها ويحمل `cordis.patch.yml` الخاص بالمستخدم |
| **bundle (حزمة)** | صيغة توزيع لصفوف تكوين Cordis والكود الذي يُركّبه — تبقى قابلة للتعديل بطبقات أعلى |

الترتيب عند الإقلاع (كل طبقة ترى ما قبلها ويمكنها استبداله):
الحزم في ترتيب البروفايل → `cordis.patch.yml` للبروفايل → مستوى home → أي `--patch`.

**في Docker** يُضاف overlay خاص: `docker/dsh-web.docker.patch.yml`
(يربط خادم الويب على `0.0.0.0:3080`). الأمر الكامل من سطر 44 في `Dockerfile`:

```bash
pnpm dsh --profile web --patch /workspace/docker/dsh-web.docker.patch.yml --no-open
```

لرؤية الشجرة الفعلية التي تُطلقها جهازك: `dsh --profile web --dump-config`
(قائمة بأوامر CLI: [apps/cli — dump-config](../apps/cli/src/dump-config.ts)).

## دورة الإعدادات: describe → mirror → write

الحقيقة في الخادم (Host)، والمتصفح يحمل **مرآة** لها.
الآلية من `packages/client/ui-settings/src/client/settings-mirror.ts`:

1. **describe**: المرآة تسأل الخادم عبر WebSocket: `ctx.remote.settings.describe()`
   (سطر 183 في `settings-mirror.ts`) — الجواب: القوائم المسجلة + `writable` + `hasDocument`.
2. **mirror**: الإجابات تُخزَّن كـ snapshot واحد (`getSnapshot()`) جميع مستهلكي
   الإعدادات يشتقّون منه — تكلفة البدء والحرارة خصائص لهذه الفئة لا لكل ميزة.
3. **write**: عند أي حفظ من الواجهة، إجابة الـ write تُعاد مباشرة إلى المرآة
   بـ`acceptView(view)` (سطر 61–65) — **بلا قراءة إضافية من الكابل**،
   وأي قراءة قديمة ما زالت جارية تُلغى.
4. **invalidation**: كل تغيير في الخادم يبعث invalidation؛ المرآة تعيد التحميل
   (قراءة واحدة فقط حتى لو تكررت، بآلية `inFlight + rerun`).

> أي أن "دورة `describe → mirror → apply`" ليست ثلاث خطوات منفصلة بل
> **مصدر حقيقة واحد** (خادم) و**صورة واحدة** (متصفح) مع قواعد اندماج صارمة.

## لماذا loopback فقط؟ (بما أن كل شيء صار plugin)

المفصل في **موضع واحد** — `packages/client/connection/src/client/index.ts:248`:

```ts
isLoopback: transport?.ownsHost === true
         || pageLocation === undefined
         || isLoopbackHostname(pageLocation.hostname),
```

والنتيجة المباشرة — `settings-mirror.ts` السطر 88–92 و114–115:

```ts
status: persistence === 'host' ? 'idle' : 'unavailable'
...
load() {
  if (this.persistence === 'memory') return Promise.resolve()
```

أي ثلاثة تحولات:

| الحالة | `isLoopback` | `persistence` | سلوك المرآة |
|---------|:---:|:---:|----------|
| `127.0.0.1` / `localhost` / ownsHost | ✓ | `host` | يقرأ ويتحدث إلى `settings.yaml` على القرص |
| أي عنوان آخر (IP LAN، VPN، …) | ✗ | `memory` | `status='unavailable'` من الولادة، `load()` لا يُرسل طلبًا |
| Shell يملك الـ host نفسه (desktop/SDK) | ✓ | `host` | يعمل (هذا مسار الـ desktop) |

> (الصف الثالث خاص بنشر desktop/SDK ولا ينطبق على نشر Docker.)

هذا حاجز أمان: الخادم يرفض أن "يقرأ/يكتب إعدادات جهازك" من متصفح غير جهازك.
الحل: نفق SSH يحيل `127.0.0.1` إلى المتصفح — انظر
[ar-TROUBLESHOOTING.md](ar-TROUBLESHOOTING.md) (القسم الأول).

## دورة الـ turn (بإيجاز)

من [architecture.md §Turn flow](architecture.md#turn-flow) — **خطوة (step)** طلب
نموذج واحد مع أدواتها، و**جولة (turn)** صفر أو أكثر خطوات:

```text
turn/start → claim input → assemble prompt+tools
  → agent/pre-step (قد ترفض)
    → step/start → agent/request → prepareCall
    → stream (llm/stream → agent/assistant-stream)
    → tool/call* → tools/pre-execute → tools/execute → tools/post-execute
  → step/end
  → أدوات تدين بطلب آخر؟ → الخطوة التالية
→ agent/turn-stopping → turn/end
```

الأحداث `agent/*` هي نقاط التوسع: `pre-step` (تعيد كتابة/رفض الدخل)،
`request` (تحديد المسار قبل أي commit)، `assistant-stream` (مراقبة الإخراج).

للتفصيل: [packages/core/agent-loop/README.md](../packages/core/agent-loop/README.md).

## طبقات Docker

```
node:24 (البناء)  ← pnpm 11.7.0 (من ARG PNPM_VERSION=11.7.0، Dockerfile:5) + build لكل الحزم
node:24-slim (التشغيل) ← source + node_modules
   ├── /home/node/.dsh         ← volume dsh_home
   ├── settings.yaml           ← seeded via docker/entrypoint.sh
   ├── dsh-web.docker.patch.yml
   ├── CMD  → pnpm dsh --profile web --patch … --no-open
   └── EXPOSE 3080 + healthcheck (HEAD request بـnode)
```

## مراجع

- المرجع الرسمي: [architecture.md](architecture.md)
- مقدمة Cordis: [cordis-primer.md](cordis-primer.md)
- كتالوج التكوين: [config-catalog.md](config-catalog.md)
- تفاصيل حلقة الـ agent: [packages/core/agent-loop/README.md](../packages/core/agent-loop/README.md)
- [ar-TROUBLESHOOTING.md](ar-TROUBLESHOOTING.md) — لماذا "unavailable"
- [ar-CONFIGURATION.md](ar-CONFIGURATION.md) — ما تخزنه هذه الطبقات

---
*Fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (MIT).*
