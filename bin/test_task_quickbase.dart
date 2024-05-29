import 'package:test_task_quickbase/github_freshdesk.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';

void main(List<String> arguments) async {
  final dotenv = DotEnv()..load();
  final githubToken = dotenv['GITHUB_TOKEN']!;
  final freshdeskToken = dotenv['FRESHDESK_TOKEN']!;
  final freshdeskDomain = dotenv['FRESHDESK_DOMAIN']!;
  final username = arguments[0];

  final githubFreshdesk = GitHubFreshdesk(
    githubToken: githubToken,
    freshdeskToken: freshdeskToken,
    freshdeskDomain: freshdeskDomain,
  );

  try {
    final user = await githubFreshdesk.getGitHubUser(username);
    var encoder = JsonEncoder.withIndent('  ');
    print('GitHub User: ${encoder.convert(user)}');

    // final contact = await githubFreshdesk.createOrUpdateFreshdeskContact(user);
    // print('Freshdesk Contact: ${encoder.convert(contact)}');

    print('Contact created or updated successfully.');
  } catch (e) {
    print('An error occurred: $e');
  }
}
