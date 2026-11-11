# wallabag-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [docker](https://github.com/wallabag/docker).

## What this is

A four-file TOS Docker application archive (`wallabagdocker.tar.gz`) that installs
docker on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `wallabagdocker`)
- `wallabagdocker.lang` — 23-language superset (TOS requires 14)
- `wallabagdocker.svg` — application icon (3422 bytes, 3 SVG elements)
- `docker-compose.yml` — one service, image `wallabag/wallabag:2.6.14`

## How it works

| | |
|---|---|
| Container image | `wallabag/wallabag:2.6.14` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8062/` (container port 8080) |
| Runs as | non-root, `user: "65534:65534"` |
| Persistent data | `/var/www/wallabag/data` → `/Volume1/DockerAppData/wallabagdocker/data`, `/var/www/wallabag/web/assets/images` → `/Volume1/DockerAppData/wallabagdocker/images` |
| Logs | `docker logs wallabagdocker` (stdout/stderr) |



## Design highlights

- **Non-root.** `user: "65534:65534"`; verified on real hardware (the container reports uid 65534).
- **Entrypoint wrapper**: the upstream image is built to run as root and keeps state in root-owned paths, so the compose file replaces the entrypoint with `src/entrypoint.sh`, which makes the service run as an unprivileged user. See that file for the details.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/wallabagdocker/data` | docker application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/wallabagdocker/images` | docker application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/wallabagdocker.tar.gz + .sha256
scripts/build.sh 2.6.14-2   # packaging iteration bump
scripts/build.sh 2.6.14-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/wallabagdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v2.6.14-1`**, assets `wallabagdocker.tar.gz` +
   `wallabagdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `wallabagdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.6.14-1` → automated validation → review.

## License / branding

docker is distributed by its upstream authors under **see upstream**. The container image is the official image from Docker Hub (`wallabag/wallabag:2.6.14`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- The application runs inside a container; data lives in the application data directory (`/Volume1/DockerAppData/wallabagdocker/`) as described above.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
