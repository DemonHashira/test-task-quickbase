import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:test_task_quickbase/database_helper.dart';
import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;

void main() {
  group('GitHubFreshdesk', () {
    // Verifies that getGitHubUser can successfully parse
    // and return user data from a JSON response
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

    // Ensures that getGitHubUser correctly handles the scenario
    // where the requested user does not exist
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

    // Test for when getGitHubUser throws
    // an exception given an invalid token is provided
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

    // Test that checks whether createOrUpdateFreshdeskContact can
    // successfully create a new contact when provided with valid data
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

    // Test that verifies that createOrUpdateFreshdeskContact
    // can successfully update an existing contact when provided with valid data
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

    // This test ensures that createOrUpdateFreshdeskContact correctly handles
    // the scenario where the provided data does not include an email
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

  group('Database tests', () {
    late DatabaseHelper dbHelper;
    late Database database;
    String databasePath = '';

    setUp(() {
      databasePath = path.join(Directory.current.path, 'test.db');
      dbHelper = DatabaseHelper();
      database = sqlite3.open(databasePath);

      database.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY,
          login TEXT,
          name TEXT,
          created_at TEXT
        )
      ''');

      dbHelper.resetDatabase();
    });

    tearDown(() {
      database.dispose();
      File(databasePath).deleteSync();
    });

    // Verifies that insertUser can successfully insert
    // a user into the database when provided with valid data
    test('insertUser inserts a user into the databse', () {
      try {
        final user = {
          'id': 1,
          'login': 'testuser',
          'name': 'Test User',
          'created_at': '2023-10-01T00:00:00Z'
        };
        dbHelper.insertUser(user);

        final result = dbHelper.getUsers();
        expect(result.length, 1);
        expect(result.first['login'], 'testuser');
        expect(result.first['name'], 'Test User');
        expect(result.first['created_at'], '2023-10-01T00:00:00Z');
      } catch (e) {
        print('Error: $e');
      }
    });

    // This test checks if getUsers can successfully
    // retrieve all users from the database
    test('getUsers returns all users from the database', () {
      final users = [
        {
          'id': 1,
          'login': 'testuser1',
          'name': 'Test User 1',
          'created_at': '2023-10-01T00:00:00Z'
        },
        {
          'id': 2,
          'login': 'testuser2',
          'name': 'Test User 2',
          'created_at': '2023-10-02T00:00:00Z'
        }
      ];
      for (var user in users) {
        dbHelper.insertUser(user);
      }

      final result = dbHelper.getUsers();
      expect(result.length, 2);
      expect(result[0]['login'], 'testuser1');
      expect(result[1]['login'], 'testuser2');
    });
  });
}
