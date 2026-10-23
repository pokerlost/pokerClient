# Runtime environments

The `poker_http` package exposes `Environment` and immutable `EnvironmentConfig` for main/dev/test/local.
`GatewayHttp.forEnvironment(config, serviceId)` requires a configured origin before any request.
Remote environments require HTTPS; local requires loopback. Direct-origin construction remains
available and plain HTTP is restricted to loopback there too. No environment is inferred from Git.

The application owns configuration precedence: explicit input, build/process variables, an explicitly
selected configuration file, safe defaults. Never embed credentials in Dart defines or web bundles.
No default remote endpoint or DNS record is supplied. Local clients use a published loopback port;
container names are not granted an insecure HTTP exception.

Each selected client owns a separate HTTP pool and must be closed. Environment-bound bearer calls
require matching environment and canonical origin. Caller-owned token stores/caches also separate
identity and audience/scopes. Switching environments does not transfer tokens. This configuration
contract does not implement the deferred backend gameplay transport or deploy a service.

[Development](development.md) owns the dev/lint cycle; Flutter tests/build remain manual.
