import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'database_helper.dart';

class GitHubFreshDesk {
  final String githubToken;
  final String freshDeskToken;
  final String freshdeskDomain;
  final DatabaseHelper dbHelper = DatabaseHelper();

  GitHubFreshDesk({
    required this.githubToken,
    required this.freshDeskToken,
    required this.freshdeskDomain,
  });

  // Get request method to get the the user's data
  Future<Map<String, dynamic>> getGitHubUser(String username) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$username'),
      headers: {'Authorization': 'token $githubToken'},
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      await dbHelper.insertUser({
        'login': user['login'],
        'name': user['name'],
        'created_at': user['created_at'],
      });

      return user;
    } else {
      throw Exception('Failed to load GitHub user');
    }
  }
}
