import 'package:cloud_firestore/cloud_firestore.dart';

class SearchMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tìm kiếm người dùng theo tên
  Future<QuerySnapshot> searchUsers(String typedUser) async {
    return await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: typedUser)
        .get();
  }
}