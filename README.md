# Solace Messaging API for Go

[![Test](https://github.com/SolaceProducts/solace-messaging-go-client/actions/workflows/test.yml/badge.svg)](https://github.com/SolaceProducts/solace-messaging-go-client/actions/workflows/test.yml)
[![PkgGoDev](https://pkg.go.dev/badge/solace.dev/go/messaging.svg)](https://pkg.go.dev/solace.dev/go/messaging)
[![Go Report Card](https://goreportcard.com/badge/solace.dev/go/messaging)](https://goreportcard.com/report/solace.dev/go/messaging)

The Solace Messaging API for Go (`solace.dev/go/messaging`) provides a high-performance Go client for connecting to [Solace Event Brokers](https://solace.com/products/event-broker/). It wraps the Solace C API (CCSMP) via Cgo, supporting pub/sub, request/reply, persistent messaging, and cache operations.

## Getting Started

```bash
go get solace.dev/go/messaging
```

Requires Go 1.17 or later.

- [Sample Applications](https://github.com/SolaceSamples/solace-samples-go)
- [Documentation](https://docs.solace.com/API/Messaging-APIs/Go-API/go-home.htm)
- [API Reference](https://docs.solace.com/API-Developer-Online-Ref-Documentation/go/)
- [Package on pkg.go.dev](https://pkg.go.dev/solace.dev/go/messaging)

### Supported Platforms

The API wraps the native Solace C library via Cgo. Pre-compiled static libraries are included for:

- Linux x86/x86_64 (glibc and musl/Alpine)
- Linux arm64 (glibc)
- macOS 10.15+ (x86_64)
- macOS 11.0+ (arm64)
- Windows WSL 2.0

## Development

### Prerequisites

- Go 1.17+ (1.22+ recommended for latest tooling)
- A C compiler (required by Cgo)
- Docker (for integration tests)
- A Go-enabled editor with format-on-save (e.g., VS Code with the [Go extension](https://code.visualstudio.com/docs/languages/go))

### Building

```bash
git clone https://github.com/SolaceDev/solace-messaging-go-client.git
cd solace-messaging-go-client
go build ./...
```

The library is self-contained: the native `libsolclient.a` static libraries are committed per platform in `internal/ccsmp/lib/`, so no external C library installation is needed.

### Running Unit Tests

```bash
go test ./...

# With race detection (as CI runs it)
go test -race ./...
```

### Running Integration Tests

The integration tests live in `./test/` as a **separate Go module**. They use [testcontainers](https://golang.testcontainers.org/) to spin up a Solace broker and [ToxiProxy](https://github.com/Shopify/toxiproxy) for network simulation. Docker must be running.

```bash
# Generate the SEMPv2 client (required, not committed to repo)
cd test/sempclient
go generate .
cd ..

# Install the Ginkgo test runner
go install github.com/onsi/ginkgo/v2/ginkgo@v2.23.4

# Run all integration tests
ginkgo

# Run a specific test by regex
ginkgo --focus="mytestregex"

# With debug logging
ginkgo -tags enable_debug_logging
```

**Use `ginkgo` rather than `go test`** for integration tests. The Ginkgo suite timeout is 1 hour; the default `go test` timeout is 10 minutes, which is usually too short.

To run against an external broker instead of testcontainers:

```bash
go test -tags remote
```

See [test/README.md](test/README.md) for environment variables and advanced test configurations (Kerberos, OAuth, Cache).

**IDE note:** The integration tests are a separate Go module (`./test/go.mod`). If using VS Code with gopls, open the `test/` directory in its own workspace to avoid multi-module issues.

### Static Analysis

```bash
go vet ./...
go fmt ./...

# Staticcheck (pin version to match Go version compatibility)
go install honnef.co/go/tools/cmd/staticcheck@v0.4.7
staticcheck --checks=all ./...
```

### CI/CD

**GitHub Actions** ([`test.yml`](.github/workflows/test.yml)) runs on every push, pull request, and manual dispatch:

- **Compatibility check** with Go 1.17 (build + unit tests)
- **Full lint + test suite** on Go 1.22 (Linux): build, `staticcheck`, `go vet`, `go fmt`, `go test -race`, and Ginkgo integration tests

Additional multi-platform testing (Linux x86_64, Linux ARM, Linux musl, macOS x86_64, macOS ARM) runs in an internal Jenkins pipeline. The [`Jenkinsfile`](Jenkinsfile) in this repo defines the matrix configuration.

### Investigating a CI Failure

1. Check the [GitHub Actions runs](https://github.com/SolaceProducts/solace-messaging-go-client/actions/workflows/test.yml) for the failing job and download the test artifacts (JUnit XML report, coverage).
2. Reproduce locally: run `go build ./...`, `go test -race ./...`, and `staticcheck --checks=all ./...` to catch build, unit test, or lint failures.
3. For integration test failures: ensure Docker is running, generate the SEMP client (`cd test/sempclient && go generate .`), then run `ginkgo` from the `test/` directory. Use `--focus="<test name>"` to isolate a single test.
4. Review the uploaded CI artifacts for JUnit XML reports and coverage output.

### Generated Code

Some files are generated from the C API headers and should not be edited directly. They follow the `*_generated.go` naming convention. To regenerate after C API (CCSMP) updates:

```bash
# Generate subcodes
export SOLCLIENT_H=./internal/ccsmp/lib/include/solclient/solClient.h
cd pkg/solace/subcode
go generate .

# Generate CCSMP props/enums
export SOLCACHE_H=./internal/ccsmp/lib/include/solclient/solCache.h
export SOLCLIENT_H=./internal/ccsmp/lib/include/solclient/solClient.h
cd internal/ccsmp
go generate .
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on submitting pull requests.

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE.txt) file for details.

This project packages and links against a variety of C dependencies. See [the licenses](./internal/ccsmp/lib/licenses.txt) for details.

## Code of Conduct

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v1.4%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

This project is released with a Contributor Code of Conduct. By participating in this project, you agree to abide by its terms.

## Support

- [Solace Community](https://solace.dev/community/)
- [Solace Support](https://solace.com/support)

## Resources

- [Solace Developer Portal](https://dev.solace.com)
- [Solace Technology Overview](https://solace.com/products/tech/)
- [OpenTelemetry Integration for the Solace Go API](https://github.com/SolaceProducts/pubsubplus-opentelemetry-go-integration)

---

Copyright 2021-2026 Solace Corporation. All rights reserved.
