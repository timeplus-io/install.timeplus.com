# Introduction

`install.timeplus.com` is a Netlify site (this repo) that serves the `curl | sh` install scripts and the Helm chart repository. In order to monitor download traffic, we use https://app.scarf.sh/ as a forwarding service with `d.timeplus.com` as the user-facing host. `d.timeplus.com` is a DNS CNAME (Route53) to `gateway.scarf.sh`; Scarf logs each request and issues a 307 redirect to the target configured for that package in the Scarf dashboard.

There are two different backends behind `d.timeplus.com`, depending on the file type.

## Helm charts (hosted in this repo)

Helm charts are checked into `charts/` and served by Netlify. Scarf forwards back to `install.timeplus.com`:

```
https://d.timeplus.com/charts/timeplus-proton-v*.tgz -> Route53 -> scarf.sh (307) -> https://install.timeplus.com/charts/timeplus-proton-v*.tgz
```

For any new helm chart, please create a corresponding package on scarf.sh to proxy the URL ([example](https://app.scarf.sh/packages/Timeplus/file/tpe-helm)). Otherwise the user will get 404 when visiting d.timeplus.com.

## Enterprise tarballs (hosted in S3)

The Timeplus Enterprise bare-metal packages are **not** in this repo. They are uploaded by the release pipeline to the S3 bucket `s3://timeplus-io-prod/dist/timeplus_enterprise/` (AWS account `185196963368`, us-west-1) and served by the CloudFront distribution `E2WCZUF3OUV19A` at `https://dist.timeplus.com/`. Scarf forwards there, not to `install.timeplus.com`:

```
https://d.timeplus.com/timeplus-enterprise-v3.3.1-linux-amd64.tar.gz
  -> Route53 -> scarf.sh (307)
  -> https://dist.timeplus.com/dist/timeplus_enterprise/timeplus-enterprise-v3.3.1-linux-amd64.tar.gz  (CloudFront, OAC)
  -> s3://timeplus-io-prod/dist/timeplus_enterprise/timeplus-enterprise-v3.3.1-linux-amd64.tar.gz  (origin, private bucket)
```

History: until August 2026 the tarballs were served from `https://timeplus.io/dist/...` by the old AWS account's bucket `s3://timeplus.io` and the `timeplus.io` website distribution. That bucket is retired; `dist.timeplus.com` was created so the download path lives entirely in the new account without touching the `timeplus.io` website or DNS delegation.

The bucket name is only known to CloudFront (as the origin) and to the release pipeline that uploads the packages. Scarf, `netlify.toml`, and the install scripts reference only the public URL, so changing the bucket does not require changes here — only the Scarf package target.

This repo only provides friendly aliases on top of that. `netlify.toml` 301-redirects e.g. `/stable-linux-amd64.tar.gz` and `/3.0-linux-amd64.tar.gz` to the versioned `d.timeplus.com` URL, and the install scripts (`install_3.0.sh`, `install_preview.sh`, ...) download via those aliases. To bump the stable/preview release, update the redirect targets in `netlify.toml`; the object must already exist in the bucket under `dist/timeplus_enterprise/` or the download will 404.

# Install Timeplus with curl

## Install Timeplus Proton

```bash
curl https://install.timeplus.com/oss | sh
```

## Install Timeplus Enterprise (stable release)

```bash
curl https://install.timeplus.com | sh
```

or

```bash
curl https://install.timeplus.com/stable | sh
```

## Install Timeplus Enterprise (preview release)

```bash
curl https://install.timeplus.com/preview | sh
```

## Install Timeplus Enterprise Stream Processing Demo (docker compose)

```bash
curl https://install.timeplus.com/sp-demo | sh
```

# Install a specific version of Timeplus Enterprise

Every install script does the same thing: detect OS/arch, download one tarball, `tar xf` it, `cd timeplus/bin`, and run `./timeplus start`. Which tarball it downloads is the only difference, so there are three ways to pick a version.

## 1. Release channel or major.minor alias (script)

| Command | What you get |
|---|---|
| `curl https://install.timeplus.com \| sh` | current stable (same as `/stable`) |
| `curl https://install.timeplus.com/preview \| sh` | current technical preview (v3.4.1-rc.4, same as `/3.4`) |
| `curl https://install.timeplus.com/3.4 \| sh` | latest 3.4 build (currently v3.4.1-rc.4, release candidate) |
| `curl https://install.timeplus.com/3.3 \| sh` | latest 3.3.x (v3.3.1, the current stable) |
| `curl https://install.timeplus.com/3.0 \| sh` | legacy alias for the 3.x line; same as `/3.3` today (v3.3.1) |
| `curl https://install.timeplus.com/2.9 \| sh` | latest 2.9 build (currently v2.9.0-preview.3) |
| `curl https://install.timeplus.com/2.8 \| sh` | latest 2.8.x (v2.8.19) |
| `curl https://install.timeplus.com/2.7 \| sh` | latest 2.7.x (v2.7.9) |
| `curl https://install.timeplus.com/2.6 \| sh` | latest 2.6.x (v2.6.8) |
| `curl https://install.timeplus.com/2.5 \| sh` | latest 2.5.x (v2.5.14) |
| `curl https://install.timeplus.com/2.4 \| sh` | latest 2.4.x (v2.4.29) |

The exact version behind each alias is the redirect target in `netlify.toml`; see "Maintaining versions" below.

## 2. Channel or alias tarball, no script

Use these when you want the package without auto-starting it (for example on a server you configure by hand). `<os>` is `linux` or `darwin`, `<arch>` is `amd64` or `arm64`:

```bash
curl -LO https://install.timeplus.com/stable-<os>-<arch>.tar.gz     # e.g. stable-linux-amd64.tar.gz
curl -LO https://install.timeplus.com/preview-<os>-<arch>.tar.gz
curl -LO https://install.timeplus.com/3.4-<os>-<arch>.tar.gz        # or 3.3-, 3.0-, 2.9-, ... 2.4-
tar xf *.tar.gz && cd timeplus/bin && ./timeplus start
```

These are the links used on https://www.timeplus.com/install.

## 3. Any exact version (no config needed)

Every build the release pipeline publishes is downloadable directly by its full version string, including release candidates and previews that are not aliased anywhere in this repo:

```bash
curl -LO https://d.timeplus.com/timeplus-enterprise-v<VERSION>-<os>-<arch>.tar.gz
tar xf timeplus-enterprise-v<VERSION>-<os>-<arch>.tar.gz && cd timeplus/bin && ./timeplus start
```

Examples that work today:

```bash
curl -LO https://d.timeplus.com/timeplus-enterprise-v3.4.1-rc.4-linux-amd64.tar.gz
curl -LO https://d.timeplus.com/timeplus-enterprise-v3.3.1-preview.24-darwin-arm64.tar.gz
curl -LO https://d.timeplus.com/timeplus-enterprise-v2.8.19-linux-arm64.tar.gz
```

This works because the Scarf route on `d.timeplus.com` is a template (`/timeplus-enterprise-{version}-{os}-{cpu}.tar.gz` -> `https://dist.timeplus.com/dist/timeplus_enterprise/...`), so anything present in the bucket is served. A version that does not exist returns HTTP 403 after the redirect (CloudFront cannot tell "missing" from "forbidden" on a private bucket). You can check availability without downloading:

```bash
curl -sIL https://d.timeplus.com/timeplus-enterprise-v3.4.1-rc.4-linux-amd64.tar.gz | grep HTTP
```

To install an exact version with the script behaviour, download the tarball as above and run the same steps the script does (`tar xf`, `cd timeplus/bin`, `./timeplus start`). The scripts themselves do not currently accept a version argument.

# Maintaining versions (for Timeplus engineers)

- **New stable or preview release:** update the four `stable-<os>-<arch>.tar.gz` (or `preview-...`) redirect targets in `netlify.toml` to the new `https://d.timeplus.com/timeplus-enterprise-v<VERSION>-...` URL. The tarballs must already be in `s3://timeplus-io-prod/dist/timeplus_enterprise/`; verify with the `curl -sIL ... | grep HTTP` check above before merging. Also update the `3.0-*` block if the release is on the 3.x line, since `/3.0` and `/stable` are expected to match.
- **New major.minor alias (e.g. `/3.4`):** add `install_3.4.sh` (copy an existing one and change the `DOWNLOAD_URL` prefix), a `from = "/3.4"` rewrite to it, and a `3.4-<os>-<arch>.tar.gz` redirect block (four lines) in `netlify.toml`.
- **Example:** `/3.3` and `/3.4` were added this way (`install_3.3.sh`, `install_3.4.sh`, plus their `3.3-*` / `3.4-*` redirect blocks). When 3.4 goes GA, bump the four `3.4-*` targets (and `stable-*` if it becomes the stable release).
- **Exact versions** need nothing: once the pipeline uploads to the bucket they are live on `d.timeplus.com`.
- Netlify deploys `main` automatically; changes are live within a minute or two of merging.
