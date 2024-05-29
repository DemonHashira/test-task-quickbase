import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'database_helper.dart';

class GitHubFreshDesk {
  final String githubToken;
  final String freshdeskToken;
  final String freshdeskDomain;
  final DatabaseHelper dbHelper = DatabaseHelper();

  GitHubFreshDesk({
    required this.githubToken,
    required this.freshdeskToken,
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
      }).catchError((error) {
        print('Failed to insert user into database: $error');
      });

      return user;
    } else {
      throw Exception('Failed to load GitHub user');
    }
  }

  // Create or update the Freshdesk contact
  Future<void> createOrUpdateFreshdeskContact(Map<String, dynamic> user) async {
    final email = user['email'];
    final response = await http.get(
      Uri.parse(
          'https://$freshdeskDomain.freshdesk.com/api/v2/contacts?email=$email'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final contacts = jsonDecode(response.body) as List;
      if (contacts.isNotEmpty) {
        final contactId = contacts.first['id'];
        final updateResponse = await http.put(
          Uri.parse(
              'https://$freshdeskDomain.freshdesk.com/api/v2/contacts/$contactId'),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'name': user['name'], 'email': user['email']}),
        );

        if (updateResponse.statusCode != 200) {
          throw Exception(
              'Failed to update Freshdesk contact: ${updateResponse.body}');
        }
      } else {
        final createResponse = await http.post(
          Uri.parse('https://$freshdeskDomain.freshdesk.com/api/v2/contacts'),
          headers: {
            'Authorization':
                'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'name': user['name'], 'email': user['email']}),
        );

        if (createResponse.statusCode != 201) {
          throw Exception(
              'Failed to create Freshdesk contact: ${createResponse.body}');
        }
      }
    } else {
      throw Exception('Failed to fetch Freshdesk contact: ${response.body}');
    }
  }
}
