import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';
import 'database_helper.dart';

class GitHubFreshdesk {
  final String githubToken;
  final String freshdeskToken;
  final String freshdeskDomain;
  final http.Client httpClient;
  final DatabaseHelper dbHelper = DatabaseHelper();

  GitHubFreshdesk({
    required this.githubToken,
    required this.freshdeskToken,
    required this.freshdeskDomain,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  // Get request method to get the the user's data
  Future<Map<String, dynamic>> getGitHubUser(String username) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$username'),
      headers: {'Authorization': 'token $githubToken'},
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      dbHelper.insertUser({
        'login': user['login'],
        'name': user['name'],
        'created_at': user['created_at'],
      });

      return user;
    } else {
      throw Exception('Failed to load GitHub user');
    }
  }

  // Create or update the Freshdesk contact
  Future<Tuple2<String, Map<String, dynamic>>> createOrUpdateFreshdeskContact(
      Map<String, dynamic> user) async {
    final email = user['email'];
    if (email == null) {
      throw Exception('GitHub user does not have a public email address');
    }

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

        return Tuple2('Updated', jsonDecode(updateResponse.body));
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

        return Tuple2('Created', jsonDecode(createResponse.body));
      }
    } else {
      throw Exception('Failed to fetch Freshdesk contact: ${response.body}');
    }
  }
}
