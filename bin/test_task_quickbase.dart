import 'package:test_task_quickbase/database_helper.dart';
import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';

void main(List<String> arguments) async {
  final dotenv = DotEnv()..load();
  final githubToken = dotenv['GITHUB_TOKEN']!;
  final freshdeskToken = dotenv['FRESHDESK_TOKEN']!;
  final freshdeskDomain = dotenv['FRESHDESK_DOMAIN']!;
  final username = arguments[0];
  final dbHelper = DatabaseHelper();

  final githubFreshdesk = GitHubFreshdesk(
    githubToken: githubToken,
    freshdeskToken: freshdeskToken,
    freshdeskDomain: freshdeskDomain,
  );

  // Reset the database before running the CLI
  dbHelper.resetDatabase();

  try {
    // Fetch GitHub user data and print it
    final user = await githubFreshdesk.getGitHubUser(username);
    var encoder = JsonEncoder.withIndent('  ');
    print('GitHub User: ${encoder.convert(user)}');

    print('\n');

    // Create or update Freshdesk contact with GitHub user data and print the result
    final result = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
    print(
        '${result.item1} Freshdesk Contact: ${encoder.convert(result.item2)}');

    // Fetch and print all users from the database
    final users = dbHelper.getUsers();
    print('\nDatabase content:');
    for (var user in users) {
      print(encoder.convert(user));
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}
