import 'package:test/test.dart';
import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:test_task_quickbase/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  test('getGitHubUser returns user data and saves to database', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
          jsonEncode({
            'login': 'testuser',
            'email': 'test@example.com',
            'name': 'Test User',
            'created_at': '2023-10-01T00:00:00Z'
          }),
          200);
    });
    final githubFreshdesk = GitHubFreshdesk(
      githubToken: 'fake_token',
      freshdeskToken: 'fake_token',
      freshdeskDomain: 'fake_token',
    );
    final user = await githubFreshdesk.getGitHubUser('testuser');
    expect(user['login'], 'testuser');

    final dbHelper = DatabaseHelper();
    final users = await dbHelper.getUsers();
    expect(users.isNotEmpty, true);
    expect(users.first['login'], 'testuser');
  });
}
