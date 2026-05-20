# Challenges & Troubleshooting

> توثيق التحديات الحقيقية التي واجهناها أثناء بناء البايبلاين وكيفية حلّها. هذي القائمة هي ما تستحق ذكره في العرض كدليل على عمق التجربة.

---

## 1. مسح `npm audit` كان يمر فاضياً

### المشكلة
في البداية أضفنا خطوة `npm audit` إلى الـ workflow وكان دائماً يُرجع exit code 0 حتى بعد تثبيت اعتمادية مصابة عمداً. الفريق ظنّ أن البوّابة الأمنية تعمل بينما هي فعلياً تتجاوز كل الفحوصات.

### السبب الجذري
لم يكن `package-lock.json` مدفوعاً للريبو. بدون lockfile، `npm install` في CI كان ينشئ شجرة اعتماديات فارغة لأن `package.json` نفسه كان قليل المحتوى، فلا توجد حُزَم فعلية للفحص.

### الحل
```bash
npm install                       # محلياً
git add package-lock.json
git commit -m "feat: add lockfile and audit:ci script"
```

### الدرس
أي pipeline يعتمد على `npm audit` لازم يتأكد أن lockfile مدفوع وأن `npm install` ينشئ نفس الشجرة محلياً وعلى الـ runner.

---

## 2. الإصدار "الآمن" أصبح غير آمن

### المشكلة
المواصفات الأصلية للتمرين كانت تستخدم `lodash@4.17.21` كإصدار آمن للسيناريو الناجح. عند تشغيل `npm run audit:ci` محلياً، رجع exit code != 0 أيضاً.

### السبب الجذري
قاعدة بيانات npm Advisories تحدّث باستمرار. الإصدارات التي كانت آمنة قبل أشهر ربما تظهر اليوم بثغرات `high`.

### الحل
تجربة عدة إصدارات حتى استقررنا على:
- `lodash@4.18.1` على `main` (يمر)
- `lodash@4.17.11` على `demo/security-fail` (يفشل بشكل موثوق)

### الدرس
في الإنتاج، لا تعتمد على إصدار "آمن" ثابت — اعتمد على آلية تحديث (Dependabot/Renovate) + سياسة "ارفع pin، حدّث، أعِد الـ tests".

---

## 3. ترتيب الخطوات أحدث فرقاً

### المشكلة
أول نسخة من الـ workflow كانت تبني صورة Docker قبل خطوة `Security Scan`. بناء الصورة يستغرق ~15 ثانية حتى لو الكود سيُرفض لاحقاً.

### الحل
أعدنا ترتيب الخطوات لتكون: install → security → tests → build → docker. الخطوة الأرخص والأكثر احتمالاً للفشل تجري أولاً (Fail Fast).

### الدرس
رتّب خطوات البايبلاين بحسب: (تكلفة الخطوة) × (احتمال فشلها). الفحوصات السريعة الحاسمة قبل العمليات البطيئة.

---

## 4. Discord webhook غير ثابت

### المشكلة
أحياناً Discord webhook يرجع 204 ولكن الرسالة لا تظهر في القناة، أو تتأخر دقائق.

### السبب المحتمل
- Rate limiting من Discord (10 رسائل/ثانية/webhook).
- مشاكل lookup للـ proxy داخل GitHub-hosted runners.

### الحل
أضفنا Telegram كقناة موازية:
- Telegram Bot API أسرع وأكثر استقراراً في تجاربنا.
- استخدمنا `continue-on-error: true` لكل قناة، فلو فشلت قناة لا يتغير شيء سوى ضياع تنبيه واحد.

### الدرس
لا تعتمد على قناة تنبيه واحدة لأحداث حرجة. التكرار في قنوات (Telegram + Discord + Email) رخيص ويقلل المخاطر.

---

## 5. التوكن انكشف في الـ chat

### المشكلة
أثناء تطوير البوت، تم لصق `TELEGRAM_BOT_TOKEN` نصياً في محادثة. هذي تُعدّ تسريباً تلقائياً يجب علاجه.

### الحل
1. من BotFather: `/revoke` لإلغاء التوكن المسرّب.
2. توليد توكن جديد من نفس الواجهة.
3. تحديث `gh secret set TELEGRAM_BOT_TOKEN --body "<new>"`.
4. لا تغيير على الكود لأن المرجعية عبر `secrets.TELEGRAM_BOT_TOKEN`.

### الدرس
حتى داخل فريق صغير، عامل أي توكن كأنه مكشوف فور كتابته في أي مكان غير Secrets Manager. خصّص قناة "secret-share" بحذف تلقائي أو استخدم 1Password / Bitwarden.

---

## 6. تنبيه Node 20 deprecation

### المشكلة
GitHub Actions يطبع warning مستمراً:

> Node.js 20 actions are deprecated. Actions will be forced to run with Node.js 24 by default starting June 2nd, 2026.

### السبب
`actions/checkout@v4` و `actions/setup-node@v4` يعملان داخلياً على Node.js 20.

### الحل (المؤجَّل)
- مراقبة إصدارات جديدة من الـ actions تدعم Node 24.
- ترقية قبل 2026-06-02.
- خيار سريع: `env: FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.

### الدرس
warning اليوم = error غداً. ابنِ عادة قراءة annotations في كل run.

---

## 7. Docker HEALTHCHECK يحتاج `curl`

### المشكلة
`node:20-slim` لا تأتي بـ `curl` افتراضياً، فالـ HEALTHCHECK كان دائماً يفشل.

### الحل
```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

### الدرس
في الصور الـ slim، تأكد من توفّر الأدوات التي يحتاجها الـ HEALTHCHECK (curl أو wget أو nc) قبل الاعتماد عليها.

---

## 8. تنسيق رسائل Telegram

### المشكلة
أول محاولة لإرسال رسالة بـ HTML failed because of أحرف خاصة في الـ commit message (مثل `<` و `>` غير الـ tags المقصودة).

### الحل
استخدمنا `jq` لبناء الـ JSON بشكل آمن:

```bash
jq -n --arg chat "$TELEGRAM_CHAT_ID" --arg text "$TEXT" \
   '{chat_id: ($chat|tonumber), text: $text, parse_mode: "HTML", disable_web_page_preview: true}'
```

### الدرس
لا تبنِ JSON يدوياً في bash؛ استخدم `jq -n --arg` ليتعامل مع الـ escaping بأمان.

---

## ملخّص الـ Takeaways

1. lockfile موجود + مدفوع = شرط أساسي لـ `npm audit` ذي معنى.
2. أمان المكتبات هو هدف متحرّك — التحديث المستمر أهم من اختيار "إصدار آمن" لمرة واحدة.
3. Fail-fast = security gates مبكرة في البايبلاين.
4. Multi-channel alerting رخيص ويُنقذ من توقّف قناة واحدة.
5. Secrets في Secrets Manager فقط، حتى داخل الفريق.
6. Warnings ليست ضوضاء — تتبّعها قبل ما تتحول لـ errors.
