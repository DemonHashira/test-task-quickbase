# Test Task QuickBase

A sample command-line application written in Dart. This project demonstrates integrating with external APIs, such as GitHub and Freshdesk, and storing data locally using SQLite. It retrieves a GitHub User's information and creates a new Contact or updates an existing contact in Freshdesk.

## Project Structure

```plaintext
test-task-quickbase/
│
├── bin/
│   └── test_task_quickbase.dart         # Entry point for the application
│
├── lib/
│   ├── github_freshdesk.dart            # Main library code
│   └── database_helper.dart             # Helper class for database operations
│
├── test/
│   └── github_freshdesk_test.dart       # Unit tests
│
├── .dart_tool/                          # Dart tool configurations
│
├── .git/                                # Git configurations and hooks
│
├── .env                                 
├── .gitignore                           
├── analysis_options.yaml                
├── pubspec.yaml                         
├── pubspec.lock                         
├── github_users.db                      
├── LICENSE                              
├── CHANGELOG.md                         
├── README.md                            
```
# Getting Started
### Prerequisites
* Dart SDK: https://dart.dev/get-dart

### Installation
1. Clone the repo:
```
git clone https://github.com/your-repo/test-task-quickbase.git
cd test-task-quickbase
```
2. Install the dependencies:
```
dart pub get
```
### Setting env variables
1. Create a .env file in the root directory of the project.
2. Add your environment-specific variables in the following format:
```
KEY1=value1
KEY2=value2
```
### Running the application
In the root of the project run:
```
dart run bin/test_task_quickbase.dart
```
### Running the tests:
Run the following command in the root:
```
dart test
```
### Libraries Used 
* http: For making HTTP requests.

* sqflite: For SQLite database operations.
* path: For handling file system paths.
* dotenv: For handling the env variables
* tuple: For handling the output
