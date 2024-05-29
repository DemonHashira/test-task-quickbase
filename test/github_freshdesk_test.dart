import 'dart:convert';
import 'package:test/test.dart';
import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GitHubFreshdesk', () {
    test('getGitHubUser returns user data', () async {
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
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );

      final user = await githubFreshdesk.getGitHubUser('testuser');
      expect(user['login'], 'testuser');
      expect(user['email'], 'test@example.com');
    });

    test('getGitHubUser throws an exception for a non-existent user', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final githubFreshdesk = GitHubFreshdesk(
        githubToken: 'fake_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );

      expect(() async => await githubFreshdesk.getGitHubUser('nonexistentuser'),
          throwsException);
    });

    test('getGitHubUser throws an exception for an invalid token', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final githubFreshdesk = GitHubFreshdesk(
        githubToken: 'invalid_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );

      expect(() async => await githubFreshdesk.getGitHubUser('testuser'),
          throwsException);
    });

    test('createOrUpdateFreshdeskContact creates a new contact', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        } else if (request.method == 'POST') {
          return http.Response(
              jsonEncode({
                'id': 123,
                'name': 'Test User',
                'email': 'test@example.com',
              }),
              201);
        }
        return http.Response('Bad Request', 400);
      });

      final githubFreshdesk = GitHubFreshdesk(
        githubToken: 'fake_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );

      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': 'test@example.com',
        'created_at': '2023-10-01T00:00:00Z'
      };

      final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
      expect(result.item1, 'Created');
      expect(result.item2['email'], 'test@example.com');
    });

    test('createOrUpdateFreshdeskContact updates an existing contact',
        () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
              jsonEncode([
                {'id': 123, 'name': 'Old Name', 'email': 'test@example.com'}
              ]),
              200);
        } else if (request.method == 'PUT') {
          return http.Response(
              jsonEncode({
                'id': 123,
                'name': 'Test User',
                'email': 'test@example.com',
              }),
              200);
        }
        return http.Response('Bad Request', 400);
      });

      final githubFreshdesk = GitHubFreshdesk(
        githubToken: 'fake_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );

      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': 'test@example.com',
        'created_at': '2023-10-01T00:00:00Z'
      };

      final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
      expect(result.item1, 'Updated');
      expect(result.item2['name'], 'Test User');
    });

    test('createOrUpdateFreshdeskContact throws an exception for missing email',
        () async {
      final githubFreshdesk = GitHubFreshdesk(
        githubToken: 'fake_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
      );

      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': null,
        'created_at': '2023-10-01T00:00:00Z'
      };

      expect(
          () async =>
              await githubFreshdesk.createOrUpdateFreshdeskContact(user),
          throwsException);
    });
  });
}
