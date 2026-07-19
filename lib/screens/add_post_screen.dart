import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/models/user.dart' as model; 
import 'package:instagram_clone/resources/firestore_methods.dart'; // Mọi logic lấy từ đây
import 'package:instagram_clone/utils/utils.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  String _uid = '';
  String _username = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _getUserData(); // Gọi hàm lấy dữ liệu user ngay khi mở màn hình
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // UI CHỈ NHẬN DỮ LIỆU ĐÃ ĐƯỢC XỬ LÝ SẴN TỪ FIRESTORE METHODS
  void _getUserData() async {
    try {
      model.User user = await FirestoreMethods().getUserDetails();
      
      if (mounted) {
        setState(() {
          _uid = user.uid;
          _username = user.username;
          _avatarUrl = user.photoUrl;
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu người dùng: $e");
    }
  }

  // Chọn ảnh từ thư viện
  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Tạo bài viết mới'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chụp ảnh mới'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.camera);
                setState(() => _file = file);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chọn từ thư viện'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.gallery);
                setState(() => _file = file);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void clearImage() {
    setState(() {
      _file = null;
      _descriptionController.clear();
    });
  }

  // UI CHỈ KÍCH HOẠT HÀM UPLOAD VÀ XỬ LÝ HIỆU ỨNG LOADING
  void _postImage() async {
    if (_uid.isEmpty || _avatarUrl.isEmpty) {
      showSnackBar('Đang tải dữ liệu, vui lòng đợi!', context);
      return;
    }

    setState(() => _isLoading = true);

    String res = await FirestoreMethods().uploadPost(
      _descriptionController.text,
      _file!,
      _uid,
      _username,
      _avatarUrl,
    );

    if (res == "Thành công") {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showSnackBar('Đã đăng bài viết!', context);
      clearImage();
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showSnackBar(res, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _file == null
        ? Center(
            child: IconButton(
              icon: const Icon(Icons.upload, size: 50),
              onPressed: () => _selectImage(context),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearImage, 
              ),
              title: const Text('Bài viết mới'),
              centerTitle: false,
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : _postImage, 
                  child: const Text(
                    "Chia sẻ",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            body: Column(
              children: [
                _isLoading
                    ? const LinearProgressIndicator(color: Colors.blueAccent)
                    : const Padding(padding: EdgeInsets.only(top: 0)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(_avatarUrl.isNotEmpty 
                          ? _avatarUrl 
                          : 'https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083t7199g30u7.png'),
                      radius: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: "Viết chú thích...", 
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              alignment: FractionalOffset.topCenter,
                              image: MemoryImage(_file!),
                            )
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          );
  }
}