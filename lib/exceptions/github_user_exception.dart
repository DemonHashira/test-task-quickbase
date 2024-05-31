class GitHubUserException implements Exception {
  final String message;

  /// Exception for GitHub user errors
  GitHubUserException(this.message);

  @override
  String toString() => 'GitHubUserException: $message';
}
