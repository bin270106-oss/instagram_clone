import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/resources/user_methods.dart';
import 'package:instagram_clone/utils/utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  Uint8List? _image;
  String _currentPhotoUrl = '';
  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Tải thông tin hiện tại của người dùng từ Firestore
  void _getUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      var userData = snap.data() as Map<String, dynamic>;

      _usernameController.text = userData['username'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _currentPhotoUrl = userData['photoUrl'] ?? '';
      _email = userData['email'] ?? FirebaseAuth.instance.currentUser!.email ?? '';
    } catch (e) {
      if (mounted) {
        showSnackBar(context, e.toString());
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Chọn ảnh đại diện mới
  void _selectImage() async {
    Uint8List? im = await pickImage(ImageSource.gallery);
    if (im != null) {
      setState(() {
        _image = im;
      });
    }
  }

  // Lưu thông tin sau khi chỉnh sửa
  void _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    String res = await UserMethods().updateUserProfile(
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      file: _image,
      currentPhotoUrl: _currentPhotoUrl,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (res == "Thành công") {
        showSnackBar(context, "Cập nhật thông tin thành công!");
        Navigator.pop(context); // Quay về lại màn hình Profile
      } else {
        showSnackBar(context, res);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Chỉnh sửa trang cá nhân', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                  )
                : const Icon(Icons.check, color: Colors.blue),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar & Nút đổi ảnh
                  Center(
                    child: Stack(
                      children: [
                        _image != null
                            ? CircleAvatar(
                                radius: 50,
                                backgroundImage: MemoryImage(_image!),
                              )
                            : _currentPhotoUrl.isNotEmpty
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(_currentPhotoUrl),
                                  )
                                : const CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(
                                      'https://i.stack.imgur.com/l60Hf.png',
                                    ),
                                  ),
                        Positioned(
                          bottom: -10,
                          left: 60,
                          child: IconButton(
                            onPressed: _selectImage,
                            icon: const Icon(Icons.add_a_photo, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _selectImage,
                    child: const Text(
                      'Đổi ảnh đại diện',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tên người dùng
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tên người dùng (Username)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tiểu sử (Bio)
                  TextField(
                    controller: _bioController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tiểu sử (Bio)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email (Hiển thị chỉ đọc, không cho sửa email)
                  TextField(
                    controller: TextEditingController(text: _email),
                    enabled: false,
                    style: const TextStyle(color: Colors.grey),
                    decoration: const InputDecoration(
                      labelText: 'Email (Khóa)',
                      labelStyle: TextStyle(color: Colors.grey),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}