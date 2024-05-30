import 'dart:io';
import 'package:test_task_quickbase/database_helper.dart';
import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';

void main(List<String> arguments) async {
  final dotenv = DotEnv()..load();
  final githubToken = dotenv['GITHUB_TOKEN']!;
  final freshdeskToken = dotenv['FRESHDESK_TOKEN']!;
  final freshdeskDomain = dotenv['FRESHDESK_DOMAIN']!;
  final dbHelper = DatabaseHelper();
  bool updateContact = false;

  final githubFreshdesk = GitHubFreshdesk(
    githubToken: githubToken,
    freshdeskToken: freshdeskToken,
    freshdeskDomain: freshdeskDomain,
  );

  print('Welcome to the GitHub Freshdesk CLI!');
  print('===================================');
  print('');
  stdout.write('Do you want to create a new Freshdesk contact? (y/n) ');
  if (stdin.readLineSync()!.toLowerCase() != 'y') {
    stdout.write('Do you want to update an existing Freshdesk contact? (y/n) ');
    if (stdin.readLineSync()!.toLowerCase() == 'y') {
      updateContact = true;
    } else {
      print('');
      print('Next time then! See you later!');
      return;
    }
  }

  // Reset the database before running the CLI
  dbHelper.resetDatabase();

  stdout.write('Please enter a GitHub username: ');
  final username = stdin.readLineSync();
  print('');

  try {
    // Fetch GitHub user data
    final user = await githubFreshdesk.getGitHubUser(username!);
    var encoder = JsonEncoder.withIndent('  ');

    // Check if the contact already exists, unless we're updating a contact
    if (!updateContact) {
      final existingContact =
          await githubFreshdesk.checkFreshdeskContact(user['email']);
      if (existingContact != null) {
        print('A contact with this username already exists.');
        stdout.write('Do you want to update this contact? (y/n) ');
        if (stdin.readLineSync()!.toLowerCase() != 'y') {
          print('');
          print('Next time then! See you later!');
          return;
        }
      }
      print('');
    }
    // Print GitHub user data
    print('GitHub User: ${encoder.convert(user)}');
    print('');

    // Create or update Freshdesk contact with GitHub user data and print the result
    final finalResult =
        await githubFreshdesk.createOrUpdateFreshdeskContact(user);
    print(
        '${finalResult.item1} Freshdesk Contact: ${encoder.convert(finalResult.item2)}');

    // Fetch and print all users from the database
    final users = dbHelper.getUsers();
    print('\nDatabase content:');
    for (var user in users) {
      print(encoder.convert(user));
    }

    print('');
    print(
        'This is the current information after the done procedure about the user in FreshDesk, GitHub and the database.');
    print('Thank you for using the GitHub Freshdesk CLI!');
    print('See you another time!');
  } catch (e) {
    print('An error occurred: $e');
  }
}
