# GitLab Runner Setup

This directory contains a Docker-based GitLab Runner configuration for running CI/CD pipelines.

## Quick Start

### 1. Start the Runner

```bash
# Start the GitLab Runner container
docker compose -f docker-compose.gitlab-runner.yml up -d

# Or use the setup script
./scripts/gitlab-runner-setup.sh
```

### 2. Register the Runner

#### Option A: Interactive Registration

```bash
docker exec -it gitlab-runner gitlab-runner register
```

You'll be prompted for:
- **GitLab instance URL**: `https://gitlab.com` (or your self-hosted GitLab URL)
- **Registration token**: Found in your GitLab project/group at `Settings > CI/CD > Runners`
- **Description**: e.g., `riverdale-docker-runner`
- **Tags**: e.g., `docker,linux` (comma-separated)
- **Executor**: `docker`
- **Default Docker image**: e.g., `alpine:latest` or `docker:latest`

#### Option B: Non-Interactive Registration

```bash
docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com" \
  --registration-token "YOUR_REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "riverdale-docker-runner" \
  --tag-list "docker,linux" \
  --run-untagged="true" \
  --locked="false" \
  --docker-privileged="false" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

## Where to Find Your Registration Token

### For Project-Specific Runners:
1. Go to your GitLab project
2. Navigate to `Settings > CI/CD`
3. Expand the `Runners` section
4. Copy the registration token

### For Group Runners:
1. Go to your GitLab group
2. Navigate to `Settings > CI/CD`
3. Expand the `Runners` section
4. Copy the registration token

### For Instance Runners (Self-hosted GitLab only):
1. Go to Admin Area
2. Navigate to `Overview > Runners`
3. Copy the registration token

## Configuration

The runner uses Docker-in-Docker capabilities, mounting `/var/run/docker.sock` to allow building Docker images within CI/CD pipelines.

### Configuration File Location
The runner configuration is stored in:
```
${CONFIG_ROOT}/gitlab-runner/config.toml
```

### Example config.toml

After registration, you can manually edit the config if needed:

```toml
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "riverdale-docker-runner"
  url = "https://gitlab.com"
  token = "YOUR_TOKEN"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
    shm_size = 0
```

## Common Operations

### View Registered Runners
```bash
docker exec gitlab-runner gitlab-runner list
```

### Check Runner Status
```bash
docker exec gitlab-runner gitlab-runner verify
```

### View Runner Logs
```bash
docker logs -f gitlab-runner
```

### Restart Runner
```bash
docker compose -f docker-compose.gitlab-runner.yml restart
```

### Stop Runner
```bash
docker compose -f docker-compose.gitlab-runner.yml down
```

### Unregister a Runner
```bash
# Unregister by name
docker exec gitlab-runner gitlab-runner unregister --name RUNNER_NAME

# Unregister all runners
docker exec gitlab-runner gitlab-runner unregister --all-runners
```

## Using the Runner in GitLab CI/CD

Once registered, you can use the runner in your `.gitlab-ci.yml`:

### Example .gitlab-ci.yml

```yaml
# Use the runner with specific tags
build:
  tags:
    - docker
    - linux
  script:
    - echo "Building application..."
    - docker build -t myapp:latest .

# Or allow any runner if run-untagged is true
test:
  script:
    - echo "Running tests..."
    - npm test
```

### Building Docker Images in CI/CD

Since the runner has access to Docker socket, you can build images:

```yaml
build-docker-image:
  tags:
    - docker
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker tag myapp:$CI_COMMIT_SHA myapp:latest
  only:
    - main
```

## Troubleshooting

### Runner Not Appearing in GitLab
1. Check if the container is running: `docker ps | grep gitlab-runner`
2. Verify registration: `docker exec gitlab-runner gitlab-runner list`
3. Check logs: `docker logs gitlab-runner`

### Permission Denied When Building Docker Images
The runner needs access to `/var/run/docker.sock`. This is already configured in the docker-compose file.

### Runner Shows as "Offline"
1. Check if the runner container is running
2. Verify network connectivity to GitLab
3. Run: `docker exec gitlab-runner gitlab-runner verify`

### Update Runner Token (After Re-registration)
If you need to update the token:
```bash
docker exec gitlab-runner gitlab-runner unregister --all-runners
# Then register again with the new token
```

## Security Considerations

1. **Docker Socket**: The runner has access to the Docker socket, which gives it significant privileges. Ensure you trust the CI/CD pipelines that will run on this runner.

2. **Network Isolation**: The runner is on the `riverdale_network`. Ensure proper network segmentation if running sensitive workloads.

3. **Token Security**: Keep your registration token secure. Anyone with this token can register a runner.

4. **Privileged Mode**: The current configuration doesn't use privileged mode. Only enable if absolutely necessary.

## Advanced Configuration

### Concurrent Jobs
To run multiple jobs simultaneously, edit the config:
```bash
docker exec gitlab-runner gitlab-runner exec
# Then edit /etc/gitlab-runner/config.toml
# Set concurrent = 4 (or desired number)
```

### Custom Docker Images
You can specify different default images per runner or per job:
```yaml
job-with-node:
  image: node:16
  script:
    - npm install
    - npm test
```

### Cache Configuration
To speed up builds, configure cache directories in config.toml or use GitLab's cache feature in your CI/CD configuration.

## Resources

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitLab Runner Docker Executor](https://docs.gitlab.com/runner/executors/docker.html)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
