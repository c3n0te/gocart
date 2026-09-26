import 'package:pocketbase/pocketbase.dart';
import 'dart:io' show Platform;

final pb = Platform.isAndroid ? PocketBase('http://10.0.2.2:8090') : PocketBase('http://127.0.0.1:8090');
