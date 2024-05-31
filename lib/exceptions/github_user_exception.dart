class GitHubUserException implements Exception {
  final String message;

  GitHubUserException(this.message);

  @override
  String toString() => 'GitHubUserException: $message';
}
