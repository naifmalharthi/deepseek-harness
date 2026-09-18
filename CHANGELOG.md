# CHANGELOG — DSH-Arabic (fork)

هذا مستودع fork من [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
(الإصدارات الأصلية: انظر changelog/tags الأصل على GitHub).
هذا السجل يوثّق تغييرات خاصة بالـ fork فقط.

## v1.0.0 — 2026-09-18

### الإضافات (Added)
- **حزمة تعريب عربية**: `packages/client/locale/src/locales/ar/` —
  45 وحدة (43 namespace) مسجلة مركزيًا عبر `arDicts`.
  (commit `1a8aaa1aef` — `feat(locale): add Arabic language pack (proof of concept)`)
- **صورة Docker متعددة المراحل** (`Dockerfile`): `node:24` للبناء → `node:24-slim`
  للتشغيل، مع `entrypoint` يبذر `settings.yaml` بثلاث نماذج Ollama.
  (commit `c7364ffce1` — `feat(docker): add multi-stage image for DSH web UI`)
- **تكوين Docker**: `docker-compose.yml` (volume `dsh_home`، healthcheck بـ node،
  `OLLAMA_API_KEY`).
- **توثيق عربي كامل**: `README.ar.md` + `docs/ar-INSTALL.md` +
  `docs/ar-CONFIGURATION.md` + `docs/ar-TROUBLESHOOTING.md` +
  `docs/ar-ARCHITECTURE.md` + `CONTRIBUTING.ar.md` + `CHANGELOG.md`.
  (commit `fba0117d85` — `docs: add Arabic README documenting Docker + locale setup` + هذه الدفعة)

### الإصلاحات (Fixed)
- **توحيد المنفذ + عزل شبكة Docker**: المنفذ `3080 → 3080`، والشبكة
  `10.42.0.0/24` / بوابة `10.42.0.1` / IP حاوية `10.42.0.2`
  (تجنّب تداخل `192.168.0.0/20` مع شبكة المضيف).
  (commit `4d9e2d7d33` — `fix(docker): unify port to 3080 and isolate network to 10.42.0.0/24`)
- **إعادة تنظيم التعريب**: `ar.ts` → `ar/` (45 وحدة مصنّفة).
  (commit `f248f9a6ed` — `refactor(locale): split Arabic locale into modular files`)

### المتغيّرات (Changed)
- حذف `README-AR.md` القديم (4 namespaces فقط) قبل كتابة الجديد.
  (commit `850ff7670c` — `chore: update gitignore and remove outdated README-AR`)
