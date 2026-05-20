# سيناريو الديمو الكامل — Secure CI/CD Pipeline

> هذا الدليل يخطو خطوة بخطوة في عرض الديمو الحي أمام اللجنة، مع توقيت تقريبي لكل قسم وكلام جاهز للعرض.

⏱ **الوقت الإجمالي:** ~10–12 دقيقة

---

## 1. التحضير قبل العرض (افعلها قبل دخول القاعة)

- [ ] افتح المتصفح على ثلاث تبويبات:
  1. صفحة الـ Actions: `https://github.com/janalyamm/secure-cicd-devsecops-demo2/actions`
  2. الـ PR الفاشل: `https://github.com/janalyamm/secure-cicd-devsecops-demo2/pull/1`
  3. ملف `.github/workflows/main.yml` على GitHub
- [ ] افتح Telegram على قروب `DevSecOpsAlert` وضعه في وضع full-screen أو split-screen.
- [ ] افتح Discord على القناة المخصصة (إذا الـ DISCORD_WEBHOOK_URL مفعّل).
- [ ] افتح Terminal على المسار `~/secure-cicd-devsecops-demo2`.
- [ ] تأكد من `git status` نظيف وأنت على فرع `main`.
- [ ] أعد تشغيل البوت من BotFather (`/start`) إذا لم تستلم رسائل من فترة.

---

## 2. Slide 0 — مقدمة (دقيقة واحدة)

**ماذا تقول:**

> "السلام عليكم. مشروعنا اسمه Secure CI/CD Pipeline with DevSecOps. هدفه إثبات فكرة Shift-Left Security: نوقف الكود غير الآمن قبل ما يصل للإنتاج، عبر دمج فحص أمان داخل GitHub Actions يفشل البايبلاين تلقائياً ويُنبّه الفريق على Telegram و Discord."

**أظهر:** Slide العنوان + شعار الفريق.

---

## 3. Slide 1 — Architecture (دقيقتان)

**ماذا تقول:**

> "هذي معمارية المشروع. أي push أو PR على main يُشغّل runner من GitHub، الـ runner يمر على 11 خطوة. أهم بوّابتين: Security Scan (npm audit) و Docker Health Check. عند الفشل، تشتعل قناتي تنبيه — Discord و Telegram — بمعلومات الكوميت والـ run."

**أظهر:** الرسم البياني من [ARCHITECTURE.md](ARCHITECTURE.md) (Big Picture).

**نقاط للتأكيد:**
- الـ Secrets محفوظة في GitHub ولا تظهر في الكود.
- البايبلاين Fail-Closed: فشل خطوة 4 يمنع 5–9 من التشغيل.
- التنبيهات `continue-on-error: true` حتى لا تُخفي الفشل الأصلي.

---

## 4. Slide 2 — Pipeline Walkthrough (دقيقة)

**ماذا تقول:**

> "هذي الـ 11 خطوة. الترتيب مهم: نفحص الأمان قبل بناء الـ Docker — أرخص في الوقت وأقل ضرراً لو وجدنا ثغرة."

**أظهر:** ملف `main.yml` على GitHub، مرّر بسرعة على الخطوات.

---

## 5. Demo 1 — Success Scenario (دقيقتان)

### الإعداد

```bash
# في الـ Terminal
git checkout main
git pull
```

### التنفيذ

اعمل تعديل بسيط (مثلاً سطر فاضي في README أو تغيير تعليق) ثم:

```bash
git add README.md
git commit -m "demo: trigger success run"
git push origin main
```

### ما تعرضه

1. افتح صفحة Actions — ستجد run جديد بدأ.
2. مرّر للجمهور خطوات الـ run وهي تنجح واحدة واحدة (~30 ثانية).
3. لحظة وصول إشعار Telegram في القروب — أكبّر الشاشة على القروب وأظهره مباشرة:

   ```
   ✅ Pipeline Success
   Repo: janalyamm/secure-cicd-devsecops-demo2
   Branch: main
   Commit: <sha>
   All steps passed: security scan, tests, build, Docker health check.
   ```

**كلام للعرض:**

> "كل الخطوات مرّت: install, security scan, tests, build, Docker, health check. الـ container وصل healthy خلال أقل من 10 ثوانٍ. القروب على Telegram استلم تأكيد فوري."

---

## 6. Demo 2 — Failure Scenario (3 دقائق) — الأهم

### الإعداد

PR رقم 1 من فرع `demo/security-fail` مفتوح ويحتوي `lodash@^4.17.11`.

### التنفيذ

من أمام الجمهور:

```bash
# أعِد تشغيل آخر run فاشل
gh run rerun $(gh run list --branch demo/security-fail --limit 1 --json databaseId -q '.[0].databaseId')
```

أو ادفع تعديل صغير لفرع `demo/security-fail`:

```bash
git fetch origin demo/security-fail
git checkout demo/security-fail
git commit --allow-empty -m "demo: re-trigger failure"
git push
```

### ما تعرضه (بهذا الترتيب)

1. **GitHub Actions:** الـ run بدأ وتلوّن أحمر عند خطوة **Run Security Scan**.
2. **اللوغ المباشر:** افتح خطوة `Run Security Scan` — أظهر مخرجات `npm audit` التي تبيّن lodash high severity.
3. **الخطوات التالية:** Tests, Build, Docker, Health Check — كلها بـ لون رمادي `-` (skipped).
4. **Telegram:** يصل تنبيه فوري:

   ```
   🚨 Pipeline Failure
   Repo: janalyamm/secure-cicd-devsecops-demo2
   Branch: 1/merge
   Cause: a CI step failed (often: npm audit found high/critical vulnerability).
   ```
5. **Discord:** نفس الفكرة بقالب embed أحمر.

### كلام للعرض (مهم)

> "لاحظوا: قبل ما نفكر نبني Docker أو ننشر، البايبلاين رفض الكود بسبب ثغرة معروفة. هذا هو Fail-Closed. الفريق أُخبر مباشرة على قناتين مختلفتين، يعني حتى لو واحد ما يفتح GitHub، الإشعار يلحقه."

---

## 7. Demo 3 — Docker Health Check (دقيقتان)

### Healthy

```bash
docker build -t secure-cicd-demo .
docker run -d --name secure-cicd-demo -p 3000:3000 secure-cicd-demo
sleep 15
docker inspect --format='{{.State.Health.Status}}' secure-cicd-demo
# → healthy
curl http://localhost:3000/health
# → {"status":"ok"}
```

### Unhealthy

```bash
docker rm -f secure-cicd-demo
docker run -d --name secure-cicd-demo -p 3000:3000 secure-cicd-demo tail -f /dev/null
sleep 40
docker inspect --format='{{.State.Health.Status}}' secure-cicd-demo
# → unhealthy
docker rm -f secure-cicd-demo
```

**كلام للعرض:**

> "الفرق بين `running` و `healthy`. الحاوية الثانية تعمل لكن السيرفر لم يُقلع — الـ HEALTHCHECK اكتشف ذلك وأعلن unhealthy. هذا اللي يصير لو الـ deployment وصل لكنه ميت داخلياً."

---

## 8. Slide 3 — Challenges & Troubleshooting (دقيقة)

**ماذا تقول:**

> "واجهنا 3 تحديات أساسية:
> 1. أول مسح npm audit كان يمر فاضي لأن lockfile لم يكن مدفوعاً.
> 2. الإصدار 4.17.21 من lodash اللي كان آمن صار يفشل بعد تحديث Advisories.
> 3. Discord webhook ينجح في الإرسال لكن قد يتأخر؛ Telegram كان أسرع وأكثر موثوقية في تجاربنا."

أظهر [CHALLENGES_AR.md](CHALLENGES_AR.md).

---

## 9. Slide 4 — Closing (30 ثانية)

**ماذا تقول:**

> "خلاصة: نجحنا في دمج DevSecOps داخل CI/CD بشكل عملي. أي محاولة لإدخال ثغرة معروفة تُرفض تلقائياً والفريق يُنبّه. شكراً، الكلمة للأسئلة."

---

## 10. Backup Plans (لو خربت الانترنت / GitHub)

| السيناريو | الحل |
|---|---|
| GitHub Actions بطيء جداً | شغّل النسخة المحلية: `npm install lodash@4.17.11 && npm run audit:ci` |
| لا يوجد إنترنت | اعرض screenshots من `docs/screenshots/` |
| Telegram لا يستجيب | اعرض الإشعارات السابقة في القروب (Scroll up) |
| Docker لا يعمل على جهازك | استخدم تسجيل فيديو مسبق |

---

## 11. أسئلة متوقّعة وردود جاهزة

| السؤال | الرد |
|---|---|
| ليش `audit-level=high` وليس `moderate`؟ | لتقليل الـ false positives الذي يوقف البايبلاين بلا داعٍ. شركات الإنتاج تتدرج: moderate → ticket، high/critical → blocked. |
| ماذا لو الـ webhook انكشف؟ | الحل: التدوير الدوري عبر BotFather + التخزين في Secrets فقط، ولا يظهر في اللوغ. |
| ليش Telegram + Discord معاً؟ | تكرار القنوات يقلل من احتمال أن يضيع إشعار حرج بسبب عطل قناة واحدة. |
| هل npm audit يكفي؟ | لا — يجب جمعه مع Dependabot/Snyk + container scanning (Trivy) + SAST. (مذكور في [SECURITY.md](SECURITY.md)). |
