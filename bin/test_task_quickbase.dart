import 'dart:io';
import 'package:test_task_quickbase/database_helper.dart';
import 'package:test_task_quickbase/exceptions/github_user_exception.dart';
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
  stdout.write('Please enter a GitHub username: ');
  final username = stdin.readLineSync();
  print('');

  final user = await githubFreshdesk.getGitHubUser(username!);

  stdout.write('Do you want to create a new Freshdesk contact? (y/n) ');
  if (stdin.readLineSync()!.toLowerCase() != 'y') {
    stdout.write('Do you want to update an existing Freshdesk contact? (y/n) ');
    if (stdin.readLineSync()!.toLowerCase() == 'y') {
      updateContact = true;
      try {
        final checkExistenceFreshDesk =
            await githubFreshdesk.checkFreshdeskContact(user['email']);
        if (checkExistenceFreshDesk == null) {
          throw GitHubUserException(
            '\nNo contact with this username exists. \nPlease try again next time with a different username! \nGoodbye!',
          );
        }
      } catch (e) {
        if (e is GitHubUserException) {
          print(e.message);
          return;
        }
      }
    } else {
      print('');
      print('Next time then! See you later!');
      return;
    }
  }

  // Reset the database before running the CLI
  dbHelper.resetDatabase();

  try {
    // Fetch GitHub user data
    final user = await githubFreshdesk.getGitHubUser(username);
    var encoder = JsonEncoder.withIndent('  ');

    final fields = ['email', 'name', 'created_at', 'login'];
    for (var field in fields) {
      if (user[field] == null) {
        throw GitHubUserException(
          'GitHub user does not have a public $field \nPlease try again next time with a different username! \nGoodbye!',
        );
      }
    }

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
    }
    // Print GitHub user data
    print('\nGitHub User: ${encoder.convert(user)}');
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
        'This is the current information after the procedure has been done about the user in FreshDesk, GitHub and the database.');
    print('');
    print('Thank you for using the GitHub Freshdesk CLI!');
    print('See you another time!');
    print('===============================================');
  } catch (e) {
    if (e is GitHubUserException) {
      print(e.message);
    }
  }
}
