# Security scan (DevSecOps)

## What is implemented

- CI runs `npm run audit:ci`, which executes `npm audit --audit-level=high`.
- The pipeline **fails** when npm reports **high** or **critical** vulnerabilities in dependencies.
- Dependencies are pinned via `package-lock.json` so local and CI scans match.

## Severity levels

| Level    | Meaning |
|----------|---------|
| low      | Informational; usually not gated in CI |
| moderate | Track and plan fixes |
| high     | **Blocked** in this project (`--audit-level=high`) |
| critical | Always blocked in production teams |

## Reproduce failure locally

```bash
npm install lodash@4.17.11
npm run audit:ci
```

Expect a non-zero exit code and advisories mentioning `lodash`.

## Reproduce pass after fix

```bash
npm install lodash@4.18.1
npm run audit:ci
```

Expect exit code `0`.

Note: `lodash@4.17.21` may fail `npm audit` as advisories are updated over time; `main` uses a patched version that passes the gate.

## Branch strategy

| Branch | Purpose |
|--------|---------|
| `main` | Safe dependencies; success demo |
| `demo/security-fail` | Intentional vulnerable `lodash@4.17.11` for failure demo |

Do not merge `demo/security-fail` into `main` before the presentation success run.

## DevSecOps flow (presentation)

1. **Shift left** — security checks run on every push/PR, not only before release.
2. **Automated gate** — `npm audit` blocks the pipeline when risk is too high.
3. **Fail closed** — deployment steps do not run after a failed security scan.
