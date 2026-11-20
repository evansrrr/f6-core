NAME=mihomo
BINDIR=bin
BRANCH=$(shell git branch --show-current)
ifeq ($(BRANCH),Alpha)
VERSION=alpha-$(shell git rev-parse --short HEAD)
else ifeq ($(BRANCH),Beta)
VERSION=beta-$(shell git rev-parse --short HEAD)
else ifeq ($(BRANCH),)
VERSION=$(shell git describe --tags)
else
VERSION=$(shell git rev-parse --short HEAD)
endif

BUILDTIME=$(shell date -u)
GOBUILD=CGO_ENABLED=0 go build -tags with_gvisor -trimpath -ldflags '-X "github.com/metacubex/mihomo/constant.Version=$(VERSION)" \
		-X "github.com/metacubex/mihomo/constant.BuildTime=$(BUILDTIME)" \
		-w -s -buildid='

PLATFORM_LIST = \
	darwin-386 \
	darwin-amd64-compatible \
	darwin-amd64 \
	darwin-amd64-v1 \
	darwin-amd64-v2 \
	darwin-amd64-v3 \
	darwin-arm64 \
	linux-386 \
	linux-amd64-compatible \
	linux-amd64 \
	linux-amd64-v1 \
	linux-amd64-v2 \
	linux-amd64-v3 \
	linux-armv5 \
	linux-armv6 \
	linux-armv7 \
	linux-arm64 \
	linux-mips64 \
	linux-mips64le \
	linux-mips-softfloat \
	linux-mips-hardfloat \
	linux-mipsle-softfloat \
	linux-mipsle-hardfloat \
	linux-riscv64 \
	linux-loong64 \
	android-arm64 \
	freebsd-386 \
	freebsd-amd64 \
	freebsd-arm64

WINDOWS_ARCH_LIST = \
	windows-386 \
	windows-amd64-compatible \
	windows-amd64 \
	windows-amd64-v1 \
	windows-amd64-v2 \
	windows-amd64-v3 \
	windows-arm64 \
    windows-arm32v7

all:linux-amd64-v3 linux-arm64\
	darwin-amd64-v3 darwin-arm64\
 	windows-amd64-v3 windows-arm64\


darwin-all: darwin-amd64-v3 darwin-arm64

docker:
	GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-386:
	GOARCH=386 GOOS=darwin $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-amd64-compatible:
	GOARCH=amd64 GOOS=darwin GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-amd64:
	GOARCH=amd64 GOOS=darwin GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-amd64-v1:
	GOARCH=amd64 GOOS=darwin GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-amd64-v2:
	GOARCH=amd64 GOOS=darwin GOAMD64=v2 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-amd64-v3:
	GOARCH=amd64 GOOS=darwin GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

darwin-arm64:
	GOARCH=arm64 GOOS=darwin $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-386:
	GOARCH=386 GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-amd64-compatible:
	GOARCH=amd64 GOOS=linux GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-amd64:
	GOARCH=amd64 GOOS=linux GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-amd64-v1:
	GOARCH=amd64 GOOS=linux GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-amd64-v2:
	GOARCH=amd64 GOOS=linux GOAMD64=v2 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-amd64-v3:
	GOARCH=amd64 GOOS=linux GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-arm64:
	GOARCH=arm64 GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-armv5:
	GOARCH=arm GOOS=linux GOARM=5 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-armv6:
	GOARCH=arm GOOS=linux GOARM=6 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-armv7:
	GOARCH=arm GOOS=linux GOARM=7 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mips-softfloat:
	GOARCH=mips GOMIPS=softfloat GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mips-hardfloat:
	GOARCH=mips GOMIPS=hardfloat GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mipsle-softfloat:
	GOARCH=mipsle GOMIPS=softfloat GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mipsle-hardfloat:
	GOARCH=mipsle GOMIPS=hardfloat GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mips64:
	GOARCH=mips64 GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-mips64le:
	GOARCH=mips64le GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

linux-riscv64:
	GOARCH=riscv64 GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@
	
linux-loong64:
	GOARCH=loong64 GOOS=linux $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

android-arm64:
	GOARCH=arm64 GOOS=android $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

freebsd-386:
	GOARCH=386 GOOS=freebsd $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

freebsd-amd64:
	GOARCH=amd64 GOOS=freebsd GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

freebsd-arm64:
	GOARCH=arm64 GOOS=freebsd $(GOBUILD) -o $(BINDIR)/$(NAME)-$@

windows-386:
	GOARCH=386 GOOS=windows $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-amd64-compatible:
	GOARCH=amd64 GOOS=windows GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-amd64:
	GOARCH=amd64 GOOS=windows GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-amd64-v1:
	GOARCH=amd64 GOOS=windows GOAMD64=v1 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-amd64-v2:
	GOARCH=amd64 GOOS=windows GOAMD64=v2 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-amd64-v3:
	GOARCH=amd64 GOOS=windows GOAMD64=v3 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-arm64:
	GOARCH=arm64 GOOS=windows $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

windows-arm32v7:
	GOARCH=arm GOOS=windows GOARM=7 $(GOBUILD) -o $(BINDIR)/$(NAME)-$@.exe

gz_releases=$(addsuffix .gz, $(PLATFORM_LIST))
zip_releases=$(addsuffix .zip, $(WINDOWS_ARCH_LIST))

$(gz_releases): %.gz : %
	chmod +x $(BINDIR)/$(NAME)-$(basename $@)
	gzip -f -S -$(VERSION).gz $(BINDIR)/$(NAME)-$(basename $@)

$(zip_releases): %.zip : %
	zip -m -j $(BINDIR)/$(NAME)-$(basename $@)-$(VERSION).zip $(BINDIR)/$(NAME)-$(basename $@).exe

all-arch: $(PLATFORM_LIST) $(WINDOWS_ARCH_LIST)

releases: $(gz_releases) $(zip_releases)

vet:
	go test ./...

lint:
	golangci-lint run ./...

clean:
	rm $(BINDIR)/*

CLANG ?= clang-14
CFLAGS := -O2 -g -Wall -Werror $(CFLAGS)

# ---------------------------------------------------------------------------
# f6-core: FreeV6 builds
#
# Two differences from upstream:
#   * F6_TAGS compiles out easytier / tailscale / zerotier (mesh-VPN outbounds
#     no proxy subscription uses; that also drops the embedded easytier binary,
#     wazero and the tailscale netstack).
#   * eight long-tail outbound protocols are removed from the tree.
# Measured on windows/amd64-v3: 58.1MB -> 38.5MB (-34%).
# Everything else -- masque, the mainstream proxy protocols, gvisor TUN, DNS,
# rule-providers, sniffer, REST API -- stays untouched.
# ---------------------------------------------------------------------------
F6_TAGS      ?= no_easytier no_zerotier no_tailscale
F6_VERSION   ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
F6_BUILDTIME ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
F6_BINDIR    ?= build
F6_LDFLAGS    = -X "github.com/metacubex/mihomo/constant.Version=$(F6_VERSION)" \
                -X "github.com/metacubex/mihomo/constant.BuildTime=$(F6_BUILDTIME)" \
                -w -s -buildid=
F6BUILD       = CGO_ENABLED=0 go build -tags "$(F6_TAGS)" -trimpath -ldflags '$(F6_LDFLAGS)'

f6-windows-amd64:
	GOARCH=amd64 GOOS=windows GOAMD64=v3 $(F6BUILD) -o $(F6_BINDIR)/f6-core-windows-amd64-v3.exe .

f6-linux-amd64:
	GOARCH=amd64 GOOS=linux GOAMD64=v3 $(F6BUILD) -o $(F6_BINDIR)/f6-core-linux-amd64 .

f6-linux-amd64-compatible:
	GOARCH=amd64 GOOS=linux GOAMD64=v1 $(F6BUILD) -o $(F6_BINDIR)/f6-core-linux-amd64-compatible .

f6-darwin-arm64:
	GOARCH=arm64 GOOS=darwin $(F6BUILD) -o $(F6_BINDIR)/f6-core-darwin-arm64 .

f6-android-arm64:
	GOARCH=arm64 GOOS=android $(F6BUILD) -o $(F6_BINDIR)/f6-core-android-arm64-v8 .

f6-all: f6-windows-amd64 f6-linux-amd64 f6-darwin-arm64 f6-android-arm64

# Compile every package with the f6 tags (catches tag-induced breakage fast).
f6-check:
	go build -tags "$(F6_TAGS)" ./...

f6-test:
	go test -tags "$(F6_TAGS)" ./adapter/... ./config/... ./rules/...

.PHONY: f6-all f6-check f6-test f6-windows-amd64 \
        f6-linux-amd64 f6-linux-amd64-compatible f6-darwin-arm64 f6-android-arm64


