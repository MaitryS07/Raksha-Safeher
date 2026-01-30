class UserModel {
  String name;
  int age;
  String phone;
  String email;
  String username;
  String bloodGroup;
  String address;

  UserModel({
    required this.name,
    required this.age,
    required this.phone,
    this.email = "",
    this.username = "",
    required this.bloodGroup,
    required this.address,
  });
}
