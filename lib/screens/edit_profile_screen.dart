import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../resources/user_methods.dart';
import '../utils/utils.dart';
import '../widgets/custom_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  Uint8List? _image;
  String _currentPhotoUrl = '';
  String _selectedGender = 'Không muốn tiết lộ'; // Mặc định
  bool _isLoading = true;
  bool _isSaving = false;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  final List<String> _genderOptions = [
    'Nữ',
    'Nam',
    'Không muốn tiết lộ',
    'Tùy chỉnh',
  ];

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Tải dữ liệu thật từ Firestore
  void _getUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (snap.exists) {
        var data = snap.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _currentPhotoUrl = data['photoUrl'] ?? '';
        
        // Đọc dữ liệu giới tính từ Firestore nếu có
        if (data['gender'] != null && _genderOptions.contains(data['gender'])) {
          _selectedGender = data['gender'];
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin user: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Chọn ảnh mới từ thư viện
  void _selectImage() async {
    Uint8List? im = await pickImage(ImageSource.gallery);
    if (im != null) {
      setState(() {
        _image = im;
      });
    }
  }

  // Gọi UserMethods để lưu thay đổi
  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true;
    });

    String res = await UserMethods().updateProfile(
      uid: uid,
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      gender: _selectedGender,
      currentPhotoUrl: _currentPhotoUrl,
      imageBytes: _image,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (res == "Thành công") {
        showSnackBar(context, 'Cập nhật trang cá nhân thành công!');
        Navigator.pop(context);
      } else {
        showSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa trang cá nhân',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF0095F6),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check,
                    color: Color(0xFF0095F6),
                    size: 28,
                  ),
            onPressed: _isSaving ? null : _updateProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KHU VỰC AVATAR
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _selectImage,
                            child: _image != null
                                ? CircleAvatar(
                                    radius: 45,
                                    backgroundImage: MemoryImage(_image!),
                                  )
                                : CustomAvatar(
                                    radius: 45,
                                    avatarUrl: _currentPhotoUrl,
                                  ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _selectImage,
                            child: const Text(
                              'Chỉnh sửa ảnh hoặc avatar',
                              style: TextStyle(
                                color: Color(0xFF0095F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ô NHẬP TÊN
                    _buildInstagramTextField(
                      label: 'Tên',
                      controller: _nameController,
                      hintText: 'Tên',
                    ),
                    const SizedBox(height: 20),

                    // Ô NHẬP USERNAME
                    _buildInstagramTextField(
                      label: 'Tên người dùng',
                      controller: _usernameController,
                      hintText: 'Tên người dùng',
                    ),
                    const SizedBox(height: 20),

                    // Ô NHẬP BIO
                    _buildInstagramTextField(
                      label: 'Tiểu sử',
                      controller: _bioController,
                      hintText: 'Tiểu sử',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Ô CHỌN GIỚI TÍNH (DROPDOWN STYLED INSTAGRAM)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giới tính',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          dropdownColor: const Color(0xFF262626),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0095F6)),
                            ),
                          ),
                          items: _genderOptions.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInstagramTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0095F6)),
            ),
          ),
        ),
      ],
    );
  }
}