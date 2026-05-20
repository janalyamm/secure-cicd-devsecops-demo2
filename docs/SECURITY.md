# Security scan (DevSecOps)

## What is implemented

- CI runs `npm run audit:ci`, which executes `npm audit --audit-level=high`.
- The pipeline **fails** when npm reports **high** or **critical** vulnerabilities in dependencies.
- Dependencies are pinned via `package-lock.json` so local and CI scans match.

## Troubleshooting during setup

During testing, the workflow initially passed even though we had added `npm audit` to CI. The reason was that the repo had no real dependencies and no `package-lock.json`, so `npm audit` had almost no installed dependency tree to scan. After running `npm install`, committing `package-lock.json`, and re-running locally, the audit step started giving consistent results in both local runs and GitHub Actions.

We also hit a version mismatch with the project brief: `lodash@4.17.21` was supposed to be the “safe” baseline, but current npm advisories flagged it as high severity. We retested a few versions and settled on `4.18.1` for `main` (pass) and `4.17.11` on `demo/security-fail` (fail), so the success and failure demos stay reproducible.

## Limitations

`npm audit` is useful for dependency scanning, but it only covers known issues in the npm advisory database. Real production pipelines often combine it with other tools (for example Dependabot, Snyk, or container image scanning) to catch more classes of risk and reduce blind spots.

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
3. **Fail closed** — if the security scan fails, the workflow stops before later stages (tests, build, Docker, or any deployment-related steps your teammates add).
