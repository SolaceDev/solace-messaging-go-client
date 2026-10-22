# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Human docs:** [README.md](README.md) | **Test docs:** [test/README.md](test/README.md) | **External docs:** [docs.solace.com/Go](https://docs.solace.com/API/Messaging-APIs/Go-API/go-home.htm) | **API ref:** [pkg.go.dev](https://pkg.go.dev/solace.dev/go/messaging)

## Repository Overview

The Solace Messaging API for Go (`solace.dev/go/messaging`) is a Go client library for Solace Event Brokers. It wraps the native C library (CCSMP/libsolclient) via Cgo, providing pub/sub, request/reply, persistent messaging, and cache APIs. Current version is in `version.go`.

## Build Commands

```bash
# Build (requires Go 1.17+, Cgo enabled)
go build ./...

# Unit tests
go test ./...

# Unit tests with race detection
go test -race ./...

# Static analysis
go vet ./...
go install honnef.co/go/tools/cmd/staticcheck@v0.4.7
staticcheck --checks=all ./...

# Format check
go fmt ./...
```

## Running Integration Tests

The integration tests live in `./test/` as a **separate Go module**. They require Docker (testcontainers spins up a Solace broker + ToxiProxy).

```bash
# Generate the SEMPv2 client (not committed; requires Docker)
cd test/sempclient && go generate . && cd ..

# Install Ginkgo (pinned version)
go install github.com/onsi/ginkgo/v2/ginkgo@v2.23.4

# Run all integration tests
ginkgo

# Run a specific test
ginkgo --focus="mytestregex"

# Debug logging
ginkgo -tags enable_debug_logging

# Against an external broker
go test -tags remote
```

## Architecture

```
User Application
    ↓
Entrypoint  (./)                               ← messaging.NewMessagingServiceBuilder()
    ↓
Public API  (pkg/solace/)                      ← interfaces, errors, lifecycle
    ↓
Implementation  (internal/impl/)               ← service, publisher, receiver impls
    ↓
Core  (internal/impl/core/)                    ← transport, events, metrics
    ↓
CCSMP Bindings  (internal/ccsmp/)              ← Cgo wrappers around libsolclient
    ↓
libsolclient  (internal/ccsmp/lib/{platform}/) ← pre-compiled static C library per platform
```

Key areas: public interfaces in `pkg/solace/`, implementation in `internal/impl/`, Cgo bindings in `internal/ccsmp/`, integration tests in `test/`.

## Generated Code — Do Not Edit

Files matching `*_generated.go` are generated from C API headers. Edit the generator scripts or source headers instead:

- `pkg/solace/subcode/subcode_generated.go` — error subcodes from `solClient.h`
- `internal/ccsmp/*_generated.go` — session/flow props, events, stats from `solClient.h` / `solCache.h`

To regenerate:

```bash
export SOLCLIENT_H=./internal/ccsmp/lib/include/solclient/solClient.h
export SOLCACHE_H=./internal/ccsmp/lib/include/solclient/solCache.h
cd pkg/solace/subcode && go generate . && cd -
cd internal/ccsmp && go generate . && cd -
```

## Gotchas & Do-Not

- **Two Go modules.** The `test/` directory has its own `go.mod` with `replace` directives pointing back to the parent module. Don't mix main-module and test-module imports. If using VS Code with gopls, open `test/` in its own workspace.
- **Cgo is required.** `CGO_ENABLED=0` builds will fail. The library links against the native C library at compile time.
- **Native libraries are committed.** The `internal/ccsmp/lib/` directory contains pre-compiled `libsolclient.a` files per platform. Don't try to build them from source or remove them.
- **`go test` timeout is too short for integration tests.** The default `go test` timeout (10 min) is insufficient. Use `ginkgo` (1 hour timeout) or pass `-timeout` explicitly.
- **SEMP client is not committed.** You must run `go generate .` in `test/sempclient/` before integration tests will compile. This requires Docker.
- **staticcheck version must match Go version.** The pinned version must be compatible with the Go version. Check the [compatibility matrix](https://github.com/dominikh/go-tools/releases) before bumping.
- **Platform-specific builds.** Code changes must compile across all supported platforms (Linux x86_64/arm64/musl, macOS x86_64/arm64). The CI runs a cross-platform matrix.
- **Public repo.** Don't commit internal URLs, credentials, or references to internal systems.
- **Don't edit `*_generated.go` files.** They are overwritten by `go generate`. See "Generated Code" above.

## Testing

- **Unit tests** (`*_test.go` alongside implementation): Standard `go test`, run in CI with race detection.
- **Integration tests** (`./test/`): Separate module using Ginkgo v2 with Gomega matchers, driven by testcontainers (Docker-based Solace broker + ToxiProxy for network simulation).
- **SEMPv2 client**: Generated from OpenAPI specs via Docker (not committed to repo; must run `go generate` in `test/sempclient/`).
- **Environment variables, ToxiProxy, Kerberos, OAuth, Cache configs**: See [test/README.md](test/README.md).

## Domain Pitfalls

- Errors from the C library surface as Go errors with subcodes (see `pkg/solace/subcode/`). An agent seeing unfamiliar error codes should check the generated subcode file, not guess.
- The API uses a **builder pattern** with property maps for configuration, not struct field assignment. Configuration keys are string constants in `pkg/solace/config/`.
- Most messaging operations are **event-driven** (callbacks and listeners), not synchronous request-response. A function returning without error doesn't mean the message was delivered — check the publish receipt callback for persistent messaging.

## CI/CD

- **GitHub Actions** (`.github/workflows/test.yml`): Runs on push/PR. Go 1.17 compatibility check + Go 1.22 full suite (build, lint, unit tests, integration tests).
- **Jenkinsfile**: Internal multi-platform CI — Linux x86_64/ARM/musl + macOS x86_64/ARM with multiple Go versions.

## Key Files

| File | Purpose |
|------|---------|
| `go.mod` | Module: `solace.dev/go/messaging`, Go 1.17 |
| `messaging.go` | Entrypoint: `NewMessagingServiceBuilder()` |
| `version.go` | API version constant |
| `test/go.mod` | Integration test module (separate) |
| `.github/workflows/test.yml` | CI pipeline |
| `Jenkinsfile` | Internal multi-platform CI |

---

> **Provenance:** This file was written with AI assistance. Where it disagrees with the source code or README, trust the source.
