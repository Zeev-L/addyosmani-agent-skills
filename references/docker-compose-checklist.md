# Docker Compose Deployment Checklist

Reference for containerized deployments using Docker Compose. Apply this checklist before any deploy. For image build and push in CI pipelines, see the "Containerized Services" section of `ci-cd-and-automation`.

---

## Naming: Lock project and container names

Without explicit names, Compose derives them from the working directory path. Path changes create duplicate containers instead of replacing existing ones.

```yaml
# docker-compose.yml
name: myproject                    # locks network/volume prefixes across machines

services:
  app:
    container_name: myproject-app  # stable name for logs, exec, and monitoring
  db:
    container_name: myproject-db
```

**Checklist:**
- [ ] `name:` is set at the top of `docker-compose.yml`
- [ ] Every service that needs a stable identity has `container_name`

---

## Image Tags: Never `latest` in production

`latest` cannot be rolled back, diffed, or audited.

```yaml
services:
  app:
    image: myapp:${IMAGE_TAG}   # set IMAGE_TAG in .env or CI environment
```

Set in `.env`:
```
IMAGE_TAG=1.4.2
# or: IMAGE_TAG=a3f8c1d  (git SHA from CI)
```

**Before any deploy**, record the current tag for rollback:
```bash
PREV_TAG=$(docker inspect myproject-app --format '{{.Config.Image}}' | cut -d: -f2)
```

**Checklist:**
- [ ] All images use explicit version tags
- [ ] `IMAGE_TAG` is pinned in `.env` or CI environment, not `latest`
- [ ] Previous tag is recorded before deploying

---

## Secrets: Runtime injection, not baked-in

`ARG` and `ENV` values in a Dockerfile persist in image layer history and are visible via `docker history` and `docker inspect`.

```yaml
services:
  app:
    env_file:
      - .env         # gitignored; populated locally or by CI
    environment:
      NODE_ENV: production   # non-secret config only
```

Commit `.env.example` with placeholder values:
```
DATABASE_URL=postgres://user:password@db:5432/mydb
SECRET_KEY=replace-me
```

Add to `.gitignore`:
```
.env
.env.prod
.env.staging
```

**Checklist:**
- [ ] No secrets in `Dockerfile` `ARG`/`ENV` or Compose `environment`
- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` is committed with placeholder values

---

## Volumes: Named volumes for persistent data

Host bind mounts with relative paths break when the working directory changes and can expose the host filesystem.

```yaml
volumes:
  db-data:       # named volume — survives container recreation
  app-uploads:

services:
  db:
    volumes:
      - db-data:/var/lib/postgresql/data   # ✅
      # NOT: - ./data:/var/lib/postgresql/data

  app:
    volumes:
      - app-uploads:/app/uploads            # ✅
      - ./src:/app/src                      # ✅ bind mount is fine for source code in dev
```

**Warning:** `docker compose down -v` deletes named volumes. Use bare `docker compose down` to preserve data.

**Checklist:**
- [ ] Stateful services (databases, file storage) use named volumes
- [ ] Bind mounts are only used for dev-time source code, not production data

---

## Networks: Explicit isolation

Without custom networks, all services share the default bridge. Explicit networks limit blast radius and enable DNS resolution by service name.

```yaml
networks:
  backend:    # db, cache, workers
  frontend:   # app, proxy

services:
  app:
    networks: [backend, frontend]
  db:
    networks: [backend]          # not reachable from frontend
  proxy:
    networks: [frontend]
    ports:
      - "80:80"                  # only the proxy exposes ports to the host
```

**Checklist:**
- [ ] Services use custom named networks
- [ ] Only the ingress/proxy service exposes ports to the host

---

## Health Checks and Startup Order

`depends_on` by default waits for the container to start, not the service inside it. Use `condition: service_healthy` to wait for readiness.

```yaml
services:
  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  app:
    depends_on:
      db:
        condition: service_healthy
```

For HTTP services:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 15s
  timeout: 5s
  retries: 3
```

**Checklist:**
- [ ] Every service others depend on has a `healthcheck`
- [ ] All `depends_on` entries for databases or caches use `condition: service_healthy`

---

## Post-Deploy Verification

```bash
# All services show "Up (healthy)"
docker compose ps

# No crash loops or startup errors
docker compose logs --tail=50 app

# Inspect health state
docker inspect myproject-app | jq '.[0].State.Health.Status'
```

**Rollback:**
```bash
# Deploy previous image tag
IMAGE_TAG=${PREV_TAG} docker compose up -d --no-deps app
docker compose ps
```
