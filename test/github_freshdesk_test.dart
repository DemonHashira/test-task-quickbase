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
    late GitHubFreshdesk githubFreshdesk;
    late MockClient mockClient;

    // Set up the mock client before each test
    setUp(() {
      mockClient = MockClient((request) async {
        if (request.url.path.endsWith('users/testuser')) {
          // Mock response for existing user
          return http.Response(
              jsonEncode({
                'login': 'testuser',
                'email': 'test@example.com',
                'name': 'Test User',
                'created_at': '2023-10-01T00:00:00Z'
              }),
              200);
        } else if (request.url.path.endsWith('users/nonexistentuser')) {
          // Mock response for non-existent user
          return http.Response('Not Found', 404);
        } else if (request.url.path.endsWith('users/invalidtokenuser')) {
          // Mock response for invalid token
          return http.Response('Unauthorized', 401);
        } else if (request.method == 'POST') {
          // Mock response for creating a contact
          return http.Response(
              jsonEncode({
                'id': 123,
                'name': 'Test User',
                'email': request.body.contains('"email":null')
                    ? null
                    : 'test@example.com',
              }),
              201);
        } else if (request.method == 'PUT') {
          // Mock response for updating a contact
          return http.Response(
              jsonEncode({
                'id': 123,
                'name': 'Test User',
                'email': 'test@example.com',
              }),
              200);
        } else if (request.method == 'GET' &&
            request.url.path.endsWith('contacts')) {
          if (request.url.queryParameters['email'] == 'test@example.com') {
            // Mock response for existing contact
            return http.Response(
                jsonEncode([
                  {'id': 123, 'name': 'Old Name', 'email': 'test@example.com'}
                ]),
                200);
          } else if (request.url.queryParameters['email'] == null) {
            // No existing contact found
            return http.Response(jsonEncode([]), 200);
          }
        }
        return http.Response('Bad Request', 400);
      });

      githubFreshdesk = GitHubFreshdesk(
        githubToken: 'fake_token',
        freshdeskToken: 'fake_token',
        freshdeskDomain: 'fake_domain',
        httpClient: mockClient,
      );
    });

    test('getGitHubUser returns user data', () async {
      // Test for valid user data retrieval
      final user = await githubFreshdesk.getGitHubUser('testuser');
      expect(user['login'], 'testuser');
      expect(user['email'], 'test@example.com');
    });

    test('getGitHubUser throws exception for non-existent user', () async {
      // Test for handling non-existent user
      expect(
        () async => await githubFreshdesk.getGitHubUser('nonexistentuser'),
        throwsA(isA<Exception>()),
      );
    });

    test('getGitHubUser throws exception for invalid token', () async {
      // Test for handling invalid token
      expect(
        () async => await githubFreshdesk.getGitHubUser('invalidtokenuser'),
        throwsA(isA<Exception>()),
      );
    });

    test('createOrUpdateFreshdeskContact creates a new contact', () async {
      // Mock client for creating a contact
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('contacts') &&
            request.url.queryParameters['email'] == 'test@example.com') {
          // No existing contact found
          return http.Response(jsonEncode([]), 200);
        } else if (request.method == 'POST') {
          // Successfully create contact
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

      // User data for testing
      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': 'test@example.com',
        'created_at': '2023-10-01T00:00:00Z'
      };

      // Test creating a new contact
      final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
      expect(result.item1, 'Created');
      expect(result.item2['email'], 'test@example.com');
    });

    test('createOrUpdateFreshdeskContact updates an existing contact',
        () async {
      // User data for testing
      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': 'test@example.com',
        'created_at': '2023-10-01T00:00:00Z'
      };

      // Test updating an existing contact
      final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
      expect(result.item1, 'Updated');
      expect(result.item2['name'], 'Test User');
    });

    test('createOrUpdateFreshdeskContact creates new contact for missing email',
        () async {
      // User data with null email
      final user = {
        'login': 'testuser',
        'name': 'Test User',
        'email': null,
        'created_at': '2023-10-01T00:00:00Z'
      };

      // Test creating a new contact
      final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
      expect(result.item1, 'Created');
      expect(result.item2['email'], null);
    });
  });

  group('Database tests', () {
    late DatabaseHelper dbHelper;
    late Database database;
    late String databasePath;

    // Set up the database before each test
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

    // Tear down the database after each test
    tearDown(() {
      database.dispose();
      if (File(databasePath).existsSync()) {
        File(databasePath).deleteSync();
      }
    });

    test('insertUser inserts a user into the database', () {
      // User data for testing
      final user = {
        'id': 1,
        'login': 'testuser',
        'name': 'Test User',
        'created_at': '2023-10-01T00:00:00Z'
      };
      dbHelper.insertUser(user);

      // Test inserting a user
      final result = dbHelper.getUsers();
      expect(result.length, 1);
      expect(result.first['login'], 'testuser');
      expect(result.first['name'], 'Test User');
      expect(result.first['created_at'], '2023-10-01T00:00:00Z');
    });

    test('getUsers returns all users from the database', () {
      // Multiple users for testing
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

      // Test retrieving all users
      final result = dbHelper.getUsers();
      expect(result.length, 2);
      expect(result[0]['login'], 'testuser1');
      expect(result[1]['login'], 'testuser2');
    });
  });
}
