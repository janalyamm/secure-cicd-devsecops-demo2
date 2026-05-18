# Security scan screenshots

## Trigger the failing pipeline

Open a pull request from `demo/security-fail` into `main`:

https://github.com/janalyamm/secure-cicd-devsecops-demo2/pull/new/demo/security-fail

The PR workflow should fail on **Run Security Scan**.

## Capture screenshots

1. Open the failed GitHub Actions run on that PR.
2. Expand the **Run Security Scan** step.
3. Save a screenshot as `audit-fail.png` in this folder for the presentation deck.

Optional: save a green **Run Security Scan** screenshot from a `main` branch run as `audit-pass.png`.
