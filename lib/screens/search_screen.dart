import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/mock_reels.dart'; 
import 'profile_screen.dart';
import 'reels_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _query = '';

  // === PHẦN THÊM MỚI: BIẾN VÀ HÀM TẢI REELS TỪ FIREBASE ===
  List<Map<String, dynamic>> _allReels = [];
  bool _isLoadingReels = true;

  @override
  void initState() {
    super.initState();
    _loadCombinedReels(); // Gọi hàm tải dữ liệu khi mở trang
  }

  // Hàm tải Reels từ Firebase và gộp với mockReels
  Future<void> _loadCombinedReels() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reels')
          .orderBy('datePublished', descending: true) // Lấy video mới nhất lên đầu
          .get();
      
      // Chuyển đổi dữ liệu Firebase cho giống format của mockReels
      final List<Map<String, dynamic>> firebaseReels = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'videoUrl': data['videoUrl'] ?? '',
          'thumbnail': data['thumbnailUrl'] ?? '', // Lấy link thumbnail
          'likes': data['likes'] != null ? (data['likes'] as List).length : 0, 
          'comments': 0, // Hiện tại chưa có comment nên gán 0
          'username': data['username'] ?? 'No Name',
          'caption': data['caption'] ?? '',
          'profileImage': data['profImage'] ?? 'https://via.placeholder.com/150',
        };
      }).toList();

      if (mounted) {
        setState(() {
          // Cú pháp gộp 2 danh sách: Bỏ Firebase Reels lên trước, mockReels xuống dưới
          _allReels = [...firebaseReels, ...mockReels];
          _isLoadingReels = false;
        });
      }
    } catch (e) {
      print("Lỗi tải reels: $e");
      if (mounted) {
        setState(() {
          _allReels = mockReels; // Lỗi thì chỉ hiện mockReels
          _isLoadingReels = false;
        });
      }
    }
  }
  // ==========================================================

  // Hàm tìm kiếm dữ liệu trên Firestore
  Future<void> _performSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _query = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = searchTerm.trim();
    });

    try {
      final String text = searchTerm.trim().toLowerCase();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: text)
          .where('username', isLessThanOrEqualTo: '$text\uf8ff')
          .get();

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Lưu lại Document ID của user
        return data;
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {}); // FIX: Gọi setState ở đây để icon X (nút Clear) hiện lên ngay lập tức khi bắt đầu gõ

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch(''); // Reset kết quả tìm kiếm
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_query.isEmpty) {
      return _buildExploreGrid(); 
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy kết quả cho "$_query"',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    // ==========================================
    // DANH SÁCH KẾT QUẢ TÌM KIẾM CÓ CHỨC NĂNG BẤM
    // ==========================================
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return InkWell(
          // KHI BẤM VÀO TÊN TÀI KHOẢN -> CHUYỂN SANG TRANG PROFILE
          onTap: () {
            // Tắt bàn phím trước khi chuyển trang cho mượt
            FocusScope.of(context).unfocus(); 
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  // Truyền UID của user được chọn qua trang Profile
                  uid: item['uid'] ?? item['id'], 
                ),
              ),
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage: NetworkImage(
                item['photoUrl'] ?? 'https://via.placeholder.com/150',
              ),
            ),
            title: Text(item['username'] ?? 'Không tên', style: const TextStyle(color: Colors.white)),
            subtitle: Text(item['bio'] ?? '', style: const TextStyle(color: Colors.grey)),
          ),
        );
      },
    );
  }

  // WIDGET LƯỚI ĐỀ XUẤT REELS (EXPLORE GRID)
  Widget _buildExploreGrid() {
    // === PHẦN THÊM MỚI: HIỂN THỊ LOADING KHI ĐANG TẢI REELS ===
    if (_isLoadingReels) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    // =========================================================

    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        crossAxisSpacing: 2, 
        mainAxisSpacing: 2,  
        childAspectRatio: 0.75, 
      ),
      // === PHẦN SỬA: Thay mockReels bằng _allReels ===
      itemCount: _allReels.length,
      itemBuilder: (context, index) {
        final reel = _allReels[index];
        String thumbnail = reel['thumbnail'] ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReelsScreen(
                  reelsList: _allReels, // Truyền danh sách đã gộp qua ReelsScreen
                  initialIndex: index, 
                ),
              ),
            );
          },
          // ==============================================
          child: Stack(
            fit: StackFit.expand,
            children: [
              //Bọc isNotEmpty để tránh lỗi văng app khi link thumbnail rỗng
              thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 30),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 30),
                      ),
                    ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.smart_display_rounded, color: Colors.white, size: 20),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${reel['likes'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}