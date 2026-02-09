import 'package:biz/base/crypt/routes.dart';
import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/security.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

abstract class DatabaseObserver {
  onDatabaseCreate(Database database, int version);

  onDatabaseUpgrade(Database database, int oldVersion, int newVersion);
}

class DataCenter {
  //生成单利
  static final DataCenter _instance = DataCenter._internal();

  factory DataCenter() => _instance;

  DataCenter._internal();

  static DataCenter get instance => _instance;

  static int version = 4;
  static String name = Security.security_soulink_db;

  Map<String, int> upgradeInfo = {};
  Map<String, int> createInfo = {};

  static String faker = Security.security_helloworld;

  late Database database;

  Future<void> init() async {
    //获取数据库路径
    var directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, name);
    //打开数据库
    database = await openDatabase(path, version: version, onCreate: onCreate, onUpgrade: onUpgrade, password: faker);
  }

  final List<DatabaseObserver> observers = <DatabaseObserver>[];

  void addObserver(DatabaseObserver observer) {
    observers.add(observer);
  }

  void onCreate(Database database, int version) async {
    createInfo[Security.security_version] = version;
    observers.map((observer) => {observer.onDatabaseCreate(database, version)});
  }

  void onUpgrade(Database database, int oldVersion, int newVersion) async {
    upgradeInfo[Security.security_oldVersion] = oldVersion;
    upgradeInfo[Security.security_newVersion] = newVersion;
    observers.map((observer) => {observer.onDatabaseUpgrade(database, oldVersion, newVersion)});
  }
}
