class ApiRequest {
  final String method;
  final Map params;

  const ApiRequest(
    this.method, {
    this.params = const {},
  });

  @override
  String toString() {
    return 'ApiRequest{method: $method, params: $params}';
  }
}
