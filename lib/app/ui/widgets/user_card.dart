import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserCard extends StatelessWidget {
  final String imgUrl;
  final String userName;
  const UserCard({super.key, required this.imgUrl, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white24,
      child: Container(
        height: Get.height * .1,
        width: double.infinity,
        child: Row(
          children: [
            CircleAvatar(child: Image.network(imgUrl)),
            Text(userName),
          ],
        ),
      ),
    );
  }
}
