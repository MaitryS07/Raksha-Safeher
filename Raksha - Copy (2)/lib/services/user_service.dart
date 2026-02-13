import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserModel? _currentUser;

  UserModel? getCurrentUser() {
    return _currentUser;
  }

  void setUser(UserModel user) {
    _currentUser = user;
  }

  void updateUser({
    String? name,
    int? age,
    String? phone,
    String? email,
    String? username,
    String? bloodGroup,
    String? address,
  }) {
    if (_currentUser == null) {
      _currentUser = UserModel(
        name: name ?? "User",
        age: age ?? 0,
        phone: phone ?? "",
        email: email ?? "",
        username: username ?? "",
        bloodGroup: bloodGroup ?? "",
        address: address ?? "",
      );
    } else {
      _currentUser = UserModel(
        name: name ?? _currentUser!.name,
        age: age ?? _currentUser!.age,
        phone: phone ?? _currentUser!.phone,
        email: email ?? _currentUser!.email,
        username: username ?? _currentUser!.username,
        bloodGroup: bloodGroup ?? _currentUser!.bloodGroup,
        address: address ?? _currentUser!.address,
      );
    }
  }

  void clearUser() {
    _currentUser = null;
  }
}

