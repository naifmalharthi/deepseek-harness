# حل المشاكل — DSH-Arabic

> جزء من التوثيق العربي لـ fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).
> نقطة البداية: [README-AR.md](../README-AR.md)

---

## رسالة "settings are unavailable in this browser"

**الأعراض**

- تبويبا "النماذج" و"الإضافات" (أو أي عنصر يحتاج قراءة إعدادات) يعرضان:
  > settings are unavailable in this browser
- لا أخطاء JavaScript — فقط رسالة فشل في التحميل.
- من `http://127.0.0.1:3080` يعمل كل شيء عاديًا، ومن أي عنوان آخر تفشل.

**السبب الجذري**

DSH يفحص عند كل اتصال: هل عنوان المتصفح loopback (`127.0.0.1`/`localhost` أم لا)?

- من `http://127.0.0.1:3080/...` → `isLoopback = true` → `persistence='host'` (يقرأ/يكتب `settings.yaml` على القرص)
- من `http://192.168.x.x:3080/...` أو أي عنوان مختلف → `isLoopback = false` → `persistence='memory'` (إعدادات مؤقتة في الذاكرة لكل جلسة، لا تقرأ ولا تكتب ملفًا)

**هذا سلوك مُصمَّم في الأصل، ليس عطلًا.**

**المرجع في الكود**

| الملف | السطر | المحتوى |
|-------|-------|---------|
| `packages/client/connection/src/client/index.ts` | 248 | `isLoopback: transport?.ownsHost === true \|\| pageLocation === undefined \|\| isLoopbackHostname(pageLocation.hostname)` |
| `packages/client/ui-settings/src/client/index.ts` | 58 | `const persistence = ctx.remote.$host.isLoopback ? 'host' : 'memory'` |
| `packages/client/ui-settings-models/src/client/store.ts` | 192 | `this.failLoad(generation, mirrored.error ?? 'settings are unavailable in this browser')` |

**الحل**

افتح المتصفح من الجهاز نفسه فقط:

```
http://127.0.0.1:3080/?token=<token>
```

إذا كنت على جهاز بعيد:

```bash
# نفق SSH محلي: يحوّل المنفذ 3080 المحلي إلى 3080 على خادم DSH
ssh -L 3080:127.0.0.1:3080 naif@<ip-of-dsh-host>
# ثم افتح في متصفحك المحلي:
# http://127.0.0.1:3080/?token=<token>
```

> ⚠️ لا تعدّل `isLoopback` كـ "hotfix" — هو حاجز أمان مُصمَّم:
> DSH لا يريد كتابة إعداداتك على القرص إلا من الجهاز نفسه.

---

## السجل (Log) يعرض منفذًا أو شبكة مختلفة عن المتوقع

**الأعراض**

- `docker ps` يعرض `0.0.0.0:3080->3080`، لكن `docker network inspect` يُظهر شبكة قديمة (مثل `192.168.0.0/20`).
- أو السجل يذكر منفذًا آخر (مثل 3081) من نسخة سابقة.

**السبب**

| الحالة | السبب |
|--------|-------|
| compose يقول `10.42.0.0/24` والحاوية على شبكة `192.168.0.0/20` | `docker compose up` لا يغيّر شبكة حاوية قائمة تلقائيًا عند تعديل قسم `networks:` في الملف |
| ذكر منفذ قديم | نسخة قديمة من `docker-compose.yml` قبل التوحيد على `3080` |

**الحل**

`docker compose down` يزيل الشبكة والحاوية القديمة (ولا يمس الـ volume):

```bash
docker compose down
docker compose up -d --build
# تحقق:
docker network inspect deepseek-harness_default --format '{{range .IPAM.Config}}{{.Subnet}} / {{.Gateway}}{{end}}'
# المنتظر: 10.42.0.0/24 / 10.42.0.1
```

---

## تعارض شبكة Docker (IP conflict)

**الأعراض**

- DSH يعمل من `127.0.0.1` لكن لا تصل إليه من أجهزة أخرى على الشبكة المحلية.
- أو `ip route` على المضيف يعرض نطاقات Docker متداخلة مع الشبكة المحلية (مثل `192.168.0.0/20` وهي نفس شبكة المنزل).
- أو تعارض مع VPN أو أي خدمة تستخدم النطاق نفسه.

**السبب**

Docker ينشئ شبكاته الفرعية ضمن `172.17–172.31` أو `192.168.x.x` كثيرًا.
إذا تطابق نطاق Docker مع شبكة المضيف الفعلية، تتعطل المسارات بين الأجهزة.

**الحل**

حدّد نطاقًا خاصًا لا يتعارض — هنا اخترنا `10.42.0.0/24`:

```yaml
networks:
  default:
    ipam:
      driver: default
      config:
        - subnet: 10.42.0.0/24
          gateway: 10.42.0.1
```

ثم:

```bash
docker compose down
docker compose up -d --build
```

> 🔍 **اختيار نطاق متاح:**
> ```bash
> ip -4 addr show | grep -E "inet 10\."    # نطاقات 10.x مخصّصة على الجهاز؟
> ip route | grep "10\.42"                 # هل يوجد مسار جاهز لهذا النطاق؟
> docker network ls                         # شبكات Docker القائمة
> ```
> إن لم يظهر شيء في المخرجين الأولين، فالنطاق متاح.

---

## تعذّر فتح ملف الإعدادات

**الأعراض**

- في الواجهة، زر "فتح ملف الإعدادات" لا يفتح شيئًا، أو يعرض رسالة فشل.

**السبب**

**قيد بيئي، ليس عطلًا.**
الزر مصمم لبيئة فيها محرّر نصوص مرتبط بالنظام (على سطح مكتب مثلاً).
داخل الخادم (headless + لا محرر)، لا يوجد ما يفتح الملف.

**الحل**

افتح الملف من سطر الأوامر على المضيف:

```bash
docker exec -it dsh-web vi /home/node/.dsh/settings.yaml
```

(طريقة التحرير اليدوي المفصّلة: [ar-CONFIGURATION.md](ar-CONFIGURATION.md) — قسم "الطريقة اليدوية")

---

## لماذا لا يعمل من جهاز آخر على الشبكة؟

نفس سبب القسم الأول: `isLoopback`.

عندما تفتح DSH من عنوان IP للشبكة (`192.168.x.x`)، يرى DSH أن المتصفح ليس
على الجهاز نفسه، فيُعيّن `isLoopback=false`، ثم `persistence='memory'`،
فتفشل قراءة الإعدادات من القرص.

هذا مُصمَّم عمداً: لا يريد DSH قراءة أو كتابة إعداداتك من جهاز عبر الشبكة.

**الحل العملي**

نفق SSH — يحوّل الطلب حتى يرى المتصفح `127.0.0.1`:

```bash
ssh -L 3080:127.0.0.1:3080 naif@<ip-dsh-host>
```

ثم افتح `http://127.0.0.1:3080/?token=<token>` في المتصفح المحلي.

> **التجاوز الكامل** يتطلب تعديل كود DSH (`isLoopback`) — غير موصى به
> ويكسر افتراض الأمان الذي بُني عليه المشروع.

---

## ملفات مرتبطة

- [ar-INSTALL.md](ar-INSTALL.md) — التثبيت الصحيح أولًا
- [ar-CONFIGURATION.md](ar-CONFIGURATION.md) — تحرير `settings.yaml`
- [ar-ARCHITECTURE.md](ar-ARCHITECTURE.md) — لماذا `isLoopback` بهذا الشكل

---
*Fork غير رسمي من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (MIT).*
