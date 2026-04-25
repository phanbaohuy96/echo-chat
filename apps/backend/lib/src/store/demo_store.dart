import '../models/user.dart';

class DemoStore {
  final Map<String, BackendUser> usersById = {};
  final Map<String, String> userIdsByUsername = {};
  final Map<String, String> userIdsByToken = {};
  final Map<String, List<Map<String, String>>> messagesByUserId = {};
}

final demoStore = DemoStore();
