# secure-cicd-devsecops-demo2

DevSecOps CI/CD demo: automated dependency security scanning in GitHub Actions.

## Security scan

The pipeline runs `npm run audit:ci` after `npm install`. If that step fails, later jobs in the workflow do not run (tests, build, etc.). See [docs/SECURITY.md](docs/SECURITY.md) for severity levels, setup issues we ran into, and how to reproduce pass/fail locally.

## Person 4 — Discord setup

1. In Discord: channel **Integrations** → **Webhooks** → **New webhook** → copy the webhook URL.
2. In GitHub: repo **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
3. Name: `DISCORD_WEBHOOK_URL`, value: the webhook URL from step 1.
4. Test: push the `demo/security-fail` branch or re-run a failed workflow; you should see an alert when any step fails.

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



