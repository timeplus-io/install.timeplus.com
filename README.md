# Introduction

The original host that hosts our binary is `install.timeplus.com`. However, in order to monitor the traffic, we use https://app.scarf.sh/ as the forward service and `d.timeplus.com` as the user-facing host.

For example, our Proton helm chart is located at `https://d.timeplus.com/charts/timeplus-proton-v1.0.0.tgz`.

```
https://d.timeplus.com/charts/timeplus-proton-v*.tgz -> Route53 -> scarf.sh -> https://install.timeplus.com/charts/timeplus-proton-v*.tgz`
```

For any new helm chart, please create a corresponding pacakge on scarf.sh to proxy the URL ([example](https://app.scarf.sh/packages/Timeplus/file/tpe-helm)). Otherwise the user will get 404 when visiting d.timeplus.com.

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
