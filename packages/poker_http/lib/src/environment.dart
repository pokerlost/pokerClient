/// Runtime identity, independent from a Git branch, service or credential.
enum Environment { main, dev, test, local }

final class EnvironmentConfig {
  EnvironmentConfig(this.environment, Map<Environment, String> endpoints)
    : endpoints = Map<Environment, String>.unmodifiable(endpoints);

  final Environment environment;
  final Map<Environment, String> endpoints;

  String resolveOrigin() {
    final endpoint = endpoints[environment];
    if (endpoint == null || endpoint.isEmpty) {
      throw StateError('Selected environment is not_configured');
    }
    return endpoint;
  }
}
