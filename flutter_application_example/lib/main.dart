import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/basic.dart' hide Row;
//import 'package:flutter_application_example/sqlite3_library_windows.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlcipher_library_windows/sqlcipher_library_windows.dart';
//import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'SQLCipher example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: [
              /* OutlinedButton(
                child: Text("Init API"),
                onPressed: () => initApiForSQLite(),
              ),*/
              OutlinedButton(
                child: Text("Create DB in mem."),
                onPressed: () => createDBInMemory(),
              ),
              OutlinedButton(
                child: Text("Create Local SQLCipher"),
                onPressed: () => createLocalDBWithSqlCipher(),
              ),
            ],
          ),
          /*Row(
            children: [
              OutlinedButton(
                child: Text("Create Local DB with PassWord"),
                onPressed: () => createDB(),
              ),
            ],
          ),*/
          Row(
            children: [
              OutlinedButton(
                child: Text("Create schema"),
                onPressed: () => createSchema(),
              )
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                child: Text("Insert rows"),
                onPressed: () => insertRows(),
              ),
              OutlinedButton(
                child: Text("Read rows"),
                onPressed: () => readRows(),
              ),
              OutlinedButton(
                child: Text("Custom function"),
                onPressed: () => createCustomFunction(),
              )
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                child: Text("Version"),
                onPressed: () => getVersion(),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  ///Init pour SQLCipher
  Future initApiForSQLiteWithSQLCipher() async {
    //Uniquement pour les appareils sous Android 6
    //await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    } else if (Platform.isWindows) {
      open.overrideFor(OperatingSystem.windows, openSQLCipherOnWindows);
      //open.overrideFor(OperatingSystem.windows, openSQLiteOnWindows);
    }
  }

  late sql.Database _db;

  ///Create DB
  void createDBInMemory() {
    initApiForSQLiteWithSQLCipher();

    // Create a new in-memory database. To use a database backed by a file, you
    // can replace this with sqlite3.open(yourFilePath).
    _db = sql.sqlite3.openInMemory();
    print(_db.userVersion);
  }

  ///Create local DB with password 'test'
  Future createLocalDBWithSqlCipher() async {
    initApiForSQLiteWithSQLCipher();

    final String password = "test";
    //Local DB file path
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filename = "$appDocPath${Platform.pathSeparator}testDB.sqlite";

    _db = sql.sqlite3.open(filename, mode: sql.OpenMode.readWriteCreate);
    if (_db.handle.address > 0) {
      print("Database created here: $filename");
      _db.execute("PRAGMA key = '$password'");
      print("Database password set: $password");
    }
  }

  ///Create Schema
  void createSchema() {
    // Create a table and insert some data
    _db.execute('''
    CREATE TABLE IF NOT EXISTS artists  (
      id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL
    );
  ''');
  }

  ///Insérer des lignes
  void insertRows() {
    // Prepare a statement to run it multiple times:
    final dynamic stmt = _db.prepare('INSERT INTO artists (name) VALUES (?)');
    stmt
      ..execute(['The Beatles'])
      ..execute(['Led Zeppelin'])
      ..execute(['The Who'])
      ..execute(['Nirvana']);

    // Dispose a statement when you don't need it anymore to clean up resources.
    stmt.dispose();
  }

  ///Read rows
  void readRows() {
    // You can run select statements with PreparedStatement.select, or directly
    // on the database:
    final sql.ResultSet resultSet =
        _db.select('SELECT * FROM artists WHERE name LIKE ?', ['The %']);

    // You can iterate on the result set in multiple ways to retrieve Row objects
    // one by one.
    resultSet.forEach((element) {
      print(element);
    });
    for (final sql.Row row in resultSet) {
      print('Artist[id: ${row['id']}, name: ${row['name']}]');
    }
  }

  ///Custom Function from Dart to Sql
  void createCustomFunction() {
    // Register a custom function we can invoke from sql:
    _db.createFunction(
      functionName: 'dart_version',
      argumentCount: const sql.AllowedArgumentCount(0),
      function: (args) => Platform.version,
    );
    print(_db.select('SELECT dart_version()'));
  }

  ///Sqlite Version
  void getVersion() {
    final sql.ResultSet resultSet = _db.select("SELECT sqlite_version()");

    // You can iterate on the result set in multiple ways to retrieve Row objects
    // one by one.
    resultSet.forEach((element) {
      print(element);
    });

    final sql.ResultSet resultSet2 = _db.select("PRAGMA cipher_version");

    // You can iterate on the result set in multiple ways to retrieve Row objects
    // one by one.
    resultSet2.forEach((element) {
      print(element);
    });
  }
}
