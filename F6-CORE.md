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

## Why this build is 32 MB instead of 58 MB

`with_gvisor` is **not** set: gVisor only serves the `mixed`/`gvisor` TUN
stacks and the client renders `stack: system`.

```
no_easytier no_zerotier no_tailscale
```

`easytier`, `tailscale` and `zerotier` are mesh-VPN outbounds. No proxy
subscription uses them as a node type, so compiling them out removes a lot of
dead weight (an embedded easytier binary, the wazero WASM runtime, the
tailscale netstack) without touching anything the client relies on.

Measured on windows/amd64-v3 with `-trimpath -ldflags "-s -w"`:

| Build | exe | download |
| --- | --- | --- |
| upstream default (gVisor) | 58.1 MiB | 22.4 MB |
| tags only (mesh-VPN out) | 39.9 MiB | 14.6 MB |
| v0.2.0 (inbounds + QUIC outbounds out) | 34.69 MiB | 12.74 MB |
| v0.3.0 (also drops gVisor) | **31.98 MiB** | **11.84 MB** |

Per-tag contribution: `no_easytier` -9.7 MB, `no_tailscale` -7.2 MB,
`no_zerotier` -1.2 MB, dropping `with_gvisor` -2.70 MiB.

On top of the tags, eight long-tail outbound protocols are removed from the
tree and from `adapter/parser.go` (-1.4 MB):

| Removed | Why |
| --- | --- |
| `snell`, `mieru`, `sudoku`, `shadowquic`, `trusttunnel`, `gost-relay` | niche transports; no Clash subscription in the wild ships them as a node type |
| `ssh`, `openvpn` | server-side protocols, never used as a proxy node in this scenario |

The mainstream set is untouched: `ss`, `ssr`, `vmess`, `vless`, `trojan`,
`anytls`, `wireguard`, `socks5`, `http`, plus `masque` (the WARP transport
FreeV6 runs on), DNS with fake-ip, rule-providers, sniffer and the REST
controller. `hysteria`, `hysteria2` and `tuic` are gone (nested QUIC cannot ride
a MASQUE chain, so they were dead options in the node picker).

> Inbound proxy *servers* went away in v0.2.0: 23 `listener/inbound` files
> deleted, `listener/parse.go` keeps only `socks` / `http` / `mixed` / `tun`
> (**-3.28 MiB**). The `listeners:` config key therefore fails with
> `unsupport proxy type: ...`; the client never emits it.

## Runtime memory

Two knobs, both opt-in, both read from the environment the client spawns the
core with:

| Env | Effect | Measured (28-node config, 1000 connections) |
| --- | --- | --- |
| `F6_IDLE_GC_SEC=N` | after N seconds without traffic, full GC + `FreeOSMemory` once. Trigger is traffic, not connection count (the masque nodes keep a remote-DNS socket open forever). Cooldown 5 min, skipped below 16 MB of returnable heap. | burst peak 107 MB → **55.6 MB** 30 s after the traffic stops (v0.3.0 stays at 104.6 MB) |
| `GOGC=60` | tighter heap goal; acts on the peak, not the tail | peak 104.7 → 95.2 MB |

The resident set is not dominated by the Go heap: with the shipped config and no
traffic, RSS 57 MB while only 13 MB is live heap (the rest is resident code
pages of a 33 MB binary, goroutine stacks, and heap arenas the scavenger has not
returned). Per connection it is ~50 KB, of which most is goroutine stacks, so
concurrency — not the ruleset — is what moves the number.

## Platforms

| Target | GOOS/GOARCH | Notes |
| --- | --- | --- |
| `windows-amd64` | windows/amd64, `GOAMD64=v3` | Primary. Needs AVX2 (Haswell+, 2013+). |
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
go build -tags "no_easytier no_zerotier no_tailscale" \
  -trimpath -ldflags "-s -w -buildid=" -o build/f6-core-windows-amd64-v3.exe .
```

## Releasing

Push a `core-v*` tag. `.github/workflows/core.yml` builds every target, runs a
size guard (a target that grows past its budget fails the build), publishes the
archives, a `SHA256SUMS.txt`, and a source tarball of the exact commit.

```bash
git tag core-v1.0.0
git push origin core-v1.0.0
```

Artifact names are `f6-core-<target>-<version>`, where `<version>` is the tag
with the `core-` prefix stripped:

```
f6-core-windows-amd64-v3-v1.0.0.zip     # contains f6-core-windows-amd64-v3.exe
f6-core-linux-amd64-v1.0.0.gz
f6-core-darwin-arm64-v1.0.0.gz
f6-core-android-arm64-v8-v1.0.0.gz
f6-core-v1.0.0-src.tar.gz
SHA256SUMS.txt
```

Every release also publishes **`core.json`**, the update manifest the client
reads to decide whether a new core is available:

```json
{
  "version": "core-v0.1.0-rc.3",
  "channel": "prerelease",
  "notes": "",
  "platforms": {
    "windows-amd64-v3": {
      "url": "https://github.com/.../releases/download/core-v0.1.0-rc.3/f6-core-windows-amd64-v3-v0.1.0-rc.3.zip",
      "sha256": "…",
      "size": 14762099
    }
  }
}
```

The platform keys must stay in sync with `CorePlatformKey()` in
`freev6/internal/mihomo/corestore.go` (`<os>-<arch>`, plus `-v3` for amd64).
The client fetches `releases/latest/download/core.json` through the gh-proxy
mirror family; since `latest` ignores prereleases, it falls back to the tag in
`coreManifestFallbackTag` until a stable core release exists.

Clients install a release by: verifying the archive's SHA256 → extracting the
single `.exe` → running `-v` and comparing the self-reported version → writing
`runtime/cores/core.json` (the pointer). The previous core is kept as the
rollback slot while the new one is unproven; as soon as the client starts the
proxy successfully with it, the slot is pruned so exactly one core stays on
disk. A start failure rolls back instead of pruning.

## License

mihomo is GPL-3.0, so this fork and every binary built from it are GPL-3.0.
The source tarball attached to each release is not a courtesy — it is the
license requirement. Do not add terms that restrict GPL rights over the core.
