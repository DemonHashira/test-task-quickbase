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
  final String freshdeskBaseUrl;

  // Constructor for GitHubFreshdesk class
  GitHubFreshdesk({
    required this.githubToken,
    required this.freshdeskToken,
    required this.freshdeskDomain,
    http.Client? httpClient,
  })  : httpClient = httpClient ?? http.Client(),
        freshdeskBaseUrl = 'https://$freshdeskDomain.freshdesk.com/api/v2';

  // Helper function to handle errors
  void handleError(http.Response response, String errorMessage) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('$errorMessage: ${response.body}');
    }
  }

  // Fetches GitHub user data
  Future<Map<String, dynamic>> getGitHubUser(String username) async {
    final response = await httpClient.get(
      Uri.parse('https://api.github.com/users/$username'),
      headers: {'Authorization': 'token $githubToken'},
    );

    // Handle error if user fetch fails
    handleError(response, 'Failed to fetch GitHub user');

    final user = jsonDecode(response.body);
    dbHelper.insertUser({
      'login': user['login'],
      'name': user['name'],
      'created_at': user['created_at'],
    });

    return user;
  }

  // Check if a contact with the given email already exists in Freshdesk
  Future<Map<String, dynamic>?> checkFreshdeskContact(String? email) async {
    if (email == null) {
      return null;
    }

    final headers = {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
      'Content-Type': 'application/json'
    };

    final response = await httpClient.get(
      Uri.parse('$freshdeskBaseUrl/contacts?email=$email'),
      headers: headers,
    );

    // Handle error if contact fetch fails
    handleError(response, 'Failed to fetch Freshdesk contact');

    final contacts = jsonDecode(response.body) as List;
    return contacts.isNotEmpty ? contacts.first : null;
  }

  // Create or update a contact in Freshdesk
  Future<Tuple2<String, Map<String, dynamic>>> createOrUpdateFreshdeskContact(
      Map<String, dynamic> user) async {
    final existingContact = await checkFreshdeskContact(user['email']);
    if (existingContact != null) {
      // Update the contact if it already exists
      final updateResponse = await httpClient.put(
        Uri.parse('$freshdeskBaseUrl/contacts/${existingContact['id']}'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': user['name'], 'email': user['email']}),
      );

      handleError(updateResponse, 'Failed to update Freshdesk contact');

      return Tuple2('Updated', jsonDecode(updateResponse.body));
    } else {
      // Create a new contact if it does not exist
      final createResponse = await httpClient.post(
        Uri.parse('$freshdeskBaseUrl/contacts'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$freshdeskToken:x'))}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': user['name'], 'email': user['email']}),
      );

      handleError(createResponse, 'Failed to create Freshdesk contact');

      return Tuple2('Created', jsonDecode(createResponse.body));
    }
  }
}
