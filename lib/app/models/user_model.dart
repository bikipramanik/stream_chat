class UserModel {
  final String uid;
  final String userName;
  final String email;
  final String imgUrl;

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.imgUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      userName: data['username'] ?? "",
      email: data['email'] ?? "",
      imgUrl: data['imageurl'] ?? "",
    );
  }
}
