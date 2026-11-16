# f6-core

A [mihomo](https://github.com/MetaCubeX/mihomo) fork that powers the FreeV6
desktop client. The fork exists to own the build: fixed upstream commits,
reproducible artifacts, and a binary that ships only what the client uses.

## Branches

| Branch | Purpose |
| --- | --- |
| `main` | Untouched upstream mirror. No commits of our own, ever. |
| `core` | The project. Build config + patches live here. |

`core` is based on upstream `Alpha` (that is where mihomo actually develops;
the upstream `main` branch has been stale since 2025-02). Syncing:

```bash
git fetch upstream --no-tags
git checkout core
git rebase upstream/Alpha   # conflicts should be rare: we only touch build files
```

## Why this build is 39.9 MB instead of 58.1 MB

The only difference from a stock build is three build tags:

```
with_gvisor no_easytier no_zerotier no_tailscale
```

`easytier`, `tailscale` and `zerotier` are mesh-VPN outbounds. No proxy
subscription uses them as a node type, so compiling them out removes a lot of
dead weight (an embedded easytier binary, the wazero WASM runtime, the
tailscale netstack) without touching anything the client relies on.

Measured on windows/amd64-v3 with `-trimpath -ldflags "-s -w"`:

| Build | exe | zip |
| --- | --- | --- |
| upstream default (`with_gvisor`) | 58.1 MB | 22.4 MB |
| this fork | **39.9 MB** | **14.6 MB** |

Per-tag contribution: `no_easytier` -9.7 MB, `no_tailscale` -7.2 MB,
`no_zerotier` -1.2 MB.

Everything else is kept on purpose: `masque` (the WARP transport FreeV6 runs
on), every proxy protocol a user might import from a subscription, gvisor TUN
(`stack: mixed` needs it), DNS with fake-ip, rule-providers, sniffer, and the
REST controller.

> Trimming the *protocol list* was measured and rejected: dropping 22 of 26
> outbound types saves only 4.6 MB and breaks legitimate subscriptions.

## Platforms

| Target | GOOS/GOARCH | Notes |
| --- | --- | --- |
| `windows-amd64` | windows/amd64, `GOAMD64=v3` | Primary. Needs AVX2 (Haswell+, 2013+). |
| `windows-amd64-compatible` | windows/amd64, `GOAMD64=v1` | For pre-AVX2 machines. |
| `linux-amd64` | linux/amd64, `GOAMD64=v3` | |
| `darwin-arm64` | darwin/arm64 | Apple Silicon. Intel Macs need a `darwin-amd64` target. |
| `android-arm64` | android/arm64 | ARMv8-A. Built with `CGO_ENABLED=0`, so it is a plain executable, not a `.so`/AAR. |

iOS is intentionally absent: an iOS build cannot be a standalone process. It
would have to be a `gomobile bind` framework (`.xcframework`) linked into the
host app, built on a macOS runner. Say the word if Flux6 needs one.

## Building

```bash
make f6-all                  # windows, linux, darwin, android
make f6-windows-amd64        # or one target at a time
make f6-check                # compile every package with the f6 tags
make f6-test                 # unit tests for config / rules / adapter
```

Artifacts land in `build/`. The raw `go build` equivalent:

```bash
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 GOAMD64=v3 \
go build -tags "with_gvisor no_easytier no_zerotier no_tailscale" \
  -trimpath -ldflags "-s -w -buildid=" -o build/mihomo-windows-amd64-v3.exe .
```

## Releasing

Push a `core-v*` tag. `.github/workflows/core.yml` builds every target, runs a
size guard (a target that grows past its budget fails the build), publishes the
archives, a `SHA256SUMS.txt`, and a source tarball of the exact commit.

```bash
git tag core-v1.0.0
git push origin core-v1.0.0
```

FreeV6 consumes the Windows zip: the archive must contain exactly one `.exe` at
its root (that is what `extractRuntime` looks for), and the release's
`SHA256SUMS.txt` is the integrity anchor for `expectedRuntimeSHA256`.

## License

mihomo is GPL-3.0, so this fork and every binary built from it are GPL-3.0.
The source tarball attached to each release is not a courtesy — it is the
license requirement. Do not add terms that restrict GPL rights over the core.
