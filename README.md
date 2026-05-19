# secure-cicd-devsecops-demo2

DevSecOps CI/CD demo: automated dependency security scanning in GitHub Actions.

## Security scan

The pipeline runs `npm run audit:ci` after `npm install`. If that step fails, later jobs in the workflow do not run (tests, build, etc.). See [docs/SECURITY.md](docs/SECURITY.md) for severity levels, setup issues we ran into, and how to reproduce pass/fail locally.

## Pipeline screenshots

### Success scenario (`main`)

Push to `main` with safe dependencies — pipeline passes, including the security scan.

![Successful pipeline run on main](docs/screenshots/pipeline-success-main.png)

### Failure scenario (`demo/security-fail` → PR to `main`)

Pull request with vulnerable `lodash@4.17.11` — workflow fails and blocks later stages.

![Failed PR workflow summary](docs/screenshots/audit-fail-summary.png)

![Failed Run Security Scan step with npm audit output](docs/screenshots/audit-fail.png)

The failure run shows **Run Tests** and **Build Project** skipped after the security gate fails (fail closed).

## Person 4 — Discord setup

1. In Discord: channel **Integrations** → **Webhooks** → **New webhook** → copy the webhook URL.
2. In GitHub: repo **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
3. Name: `DISCORD_WEBHOOK_URL`, value: the webhook URL from step 1.
4. Test: re-run a failed workflow on the `demo/security-fail` PR; you should see an alert when any step fails.

If the secret is not set, the pipeline still fails on security issues; the Discord step logs a skip message and does not block the failure signal.

## Docker Health Check Demo

This project uses a small educational Node.js HTTP server for the Docker demo. It is not a production app; it only gives the container a real endpoint for Docker health checks.

### Build Image

```bash
docker build -t secure-cicd-demo .
```

### Run Healthy Container

```bash
docker run -d --name secure-cicd-demo -p 3000:3000 secure-cicd-demo
sleep 15
docker ps
docker inspect --format='{{.State.Health.Status}}' secure-cicd-demo
curl http://localhost:3000/health
```

Expected health result:

```text
healthy
```

### Demo Unhealthy Container

Run the same image with a command that keeps the container alive but does not start the Node.js server:

```bash
docker rm -f secure-cicd-demo
docker run -d --name secure-cicd-demo -p 3000:3000 secure-cicd-demo tail -f /dev/null
sleep 40
docker inspect --format='{{.State.Health.Status}}' secure-cicd-demo
```

After the health check retries finish, expected health result:

```text
unhealthy
```

### Cleanup

```bash
docker rm -f secure-cicd-demo
```



