import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

final pbProvider = Provider<PocketBase>((ref) {
  return Platform.isAndroid ? PocketBase('http://10.0.2.2:8090') : PocketBase('http://127.0.0.1:8090');
});
