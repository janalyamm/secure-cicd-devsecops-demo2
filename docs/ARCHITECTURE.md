# Architecture — Secure CI/CD Pipeline with DevSecOps

> هذا المستند يصف المعمارية الكاملة للبايبلاين، بما في ذلك المكونات، تدفق البيانات، نقاط الفشل، وقنوات التنبيه.

---

## 1. Big Picture Diagram

```mermaid
flowchart TB
    DEV[Developer<br/>git push / open PR]
    subgraph GH[GitHub]
        REPO[(Repository<br/>secure-cicd-devsecops-demo2)]
        ACT[GitHub Actions Runner<br/>ubuntu-latest]
        SEC[/Secrets:<br/>TELEGRAM_BOT_TOKEN<br/>TELEGRAM_CHAT_ID<br/>DISCORD_WEBHOOK_URL/]
    end
    subgraph WF[Workflow: Secure CI/CD Pipeline]
        S1[1- Checkout]
        S2[2- Setup Node 18]
        S3[3- Install Dependencies]
        S4{{4- Security Scan<br/>npm audit --audit-level=high}}
        S5[5- Tests]
        S6[6- Build]
        S7[7- Build Docker Image]
        S8[8- Run Container]
        S9{{9- Docker Health Check}}
        S10[10- Stop Container - always]
        OK[Notify Telegram on success]
        FAIL_D[Notify Discord on failure]
        FAIL_T[Notify Telegram on failure]
    end
    NPM[(npm Advisory DB)]
    DISCORD[Discord Channel]
    TG[Telegram Group<br/>DevSecOpsAlert]

    DEV -->|push to main / PR| REPO
    REPO -->|trigger workflow| ACT
    ACT --> S1 --> S2 --> S3 --> S4
    S4 -.queries.-> NPM
    S4 -->|pass| S5 --> S6 --> S7 --> S8 --> S9 --> S10 --> OK
    S4 -->|fail| FAIL_D
    S9 -->|unhealthy| FAIL_D
    FAIL_D --> FAIL_T
    SEC -.injected.-> WF
    OK -->|HTTPS POST| TG
    FAIL_D -->|webhook| DISCORD
    FAIL_T -->|HTTPS POST| TG

    classDef gate fill:#ffe5e5,stroke:#cc0000,stroke-width:2px,color:#000
    classDef notify fill:#e5f3ff,stroke:#0066cc,color:#000
    class S4,S9 gate
    class OK,FAIL_D,FAIL_T notify
```

---

## 2. Component Breakdown

| المكوّن | الدور | المسؤول (في الفريق) |
|---|---|---|
| GitHub Repository | مصدر الكود ومحفّز البايبلاين | الشخص 1 |
| GitHub Actions Workflow | تنفيذ خطوات CI/CD | الشخص 1 |
| `npm audit` | فحص الثغرات في الاعتماديات | الشخص 2 |
| Dockerfile + HEALTHCHECK | حاوية + مراقبة صحة | الشخص 3 |
| Discord Webhook | قناة تنبيه احتياطية | الشخص 4 |
| Telegram Bot + Group | قناة التنبيه الرئيسية (نجاح + فشل) | الشخص 4 |
| GitHub Secrets | تخزين آمن للتوكنات | الشخص 4 |

---

## 3. Pipeline State Machine

```mermaid
stateDiagram-v2
    [*] --> Triggered: push to main / PR to main
    Triggered --> Checkout
    Checkout --> SetupNode
    SetupNode --> Install
    Install --> SecurityScan

    SecurityScan --> Tests: clean (exit 0)
    SecurityScan --> NotifyFail: high/critical found

    Tests --> Build
    Build --> DockerBuild
    DockerBuild --> DockerRun
    DockerRun --> HealthCheck

    HealthCheck --> StopContainer: healthy
    HealthCheck --> NotifyFail: unhealthy after 30s

    StopContainer --> NotifySuccess
    NotifySuccess --> [*]: Telegram ✅

    NotifyFail --> NotifyDiscord
    NotifyDiscord --> NotifyTelegramFail
    NotifyTelegramFail --> [*]: Discord + Telegram 🚨
```

---

## 4. Data Flow — رسالة التنبيه

```mermaid
sequenceDiagram
    participant R as GitHub Runner
    participant S as GitHub Secrets
    participant T as Telegram Bot API
    participant G as Telegram Group

    R->>S: read TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
    Note over R: build HTML message<br/>(repo, branch, commit, run URL)
    R->>T: POST /bot<TOKEN>/sendMessage<br/>{chat_id, text, parse_mode: HTML}
    T-->>R: {"ok": true, "message_id": N}
    T->>G: deliver formatted message
```

---

## 5. Security Gate Logic

```mermaid
flowchart LR
    A[npm install] --> B{npm audit<br/>--audit-level=high}
    B -->|low / moderate| C[exit 0]
    B -->|high / critical| D[exit 1]
    C --> E[Continue pipeline]
    D --> F[Pipeline blocked<br/>at step 4]
    F --> G[All later steps skipped]
    G --> H[Failure notifications fire]
```

---

## 6. Branch Strategy

```mermaid
gitGraph
    commit id: "init"
    commit id: "CI workflow"
    commit id: "Security scan"
    commit id: "Docker + health"
    commit id: "Telegram alert"
    branch demo/security-fail
    commit id: "Vulnerable lodash"
    checkout main
    commit id: "Continue work"
```

- **`main`** — اعتماديات آمنة. push عليه = pipeline يمر = Telegram success.
- **`demo/security-fail`** — يستخدم `lodash@^4.17.11` (ثغرة معروفة). PR منه إلى main = pipeline يفشل عند Security Scan = Telegram + Discord failure alerts.

---

## 7. Files Map

```
secure-cicd-devsecops-demo2/
│
├── .github/workflows/main.yml   ← orchestration (الشخص 1)
├── package.json                 ← deps + audit:ci (الشخص 2)
├── Dockerfile                   ← container + HEALTHCHECK (الشخص 3)
├── server.js                    ← /health endpoint (الشخص 3)
│
└── docs/
    ├── SECURITY.md              ← security gate explanation (الشخص 2)
    ├── ARCHITECTURE.md          ← this file (الشخص 4)
    ├── DEMO_FLOW_AR.md          ← presentation script (الشخص 4)
    ├── CHALLENGES_AR.md         ← issues & fixes (الشخص 4)
    ├── PRESENTATION_AR.md       ← slides content (الشخص 4)
    ├── PROJECT_OVERVIEW_AR.md   ← Arabic project overview
    └── screenshots/             ← evidence of pass/fail runs
```
