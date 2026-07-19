import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final snap; // Biến hứng dữ liệu từ home_screen truyền sang
  const PostCard({Key? key, required this.snap}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Nền đen chuẩn Dark Mode
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          _buildPostImage(),
          _buildPostActions(),
          _buildPostDetails(),
        ],
      ),
    );
  }

  // 1. Header: Avatar + Tên User + Nút More
  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(right: 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            // Lấy avatar thật, nếu không có thì dùng ảnh mặc định
            backgroundImage: NetworkImage(
              widget.snap['userHeaderImage'] ?? 'https://images.unsplash.com/photo-1682687220742-aba13b6e50ba',
            ), 
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                widget.snap['username'] ?? 'username_do_an', // Lấy tên thật
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          )
        ],
      ),
    );
  }

  // 2. Image: Khung ảnh vuông/chữ nhật
  Widget _buildPostImage() {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Image.network(
        // Ở đây tui đang để ảnh mẫu. Sau này ông đổi thành: widget.snap['postUrl'] (hoặc trường chứa link ảnh của ông)
        'https://images.unsplash.com/photo-1682687220742-aba13b6e50ba', 
        fit: BoxFit.cover,
      ),
    );
  }

  // 3. Actions: Dải nút Tim, Comment, Share, Save
  Widget _buildPostActions() {
    return Row(
      children: [
        IconButton(
          onPressed: toggleLike,
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.white,
            size: 28,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.send_outlined, color: Colors.white, size: 26),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  // 4. Details: Lượt like, Caption, Lượt comment, Ngày đăng
  Widget _buildPostDetails() {
    // Tính toán số like ảo để demo trước
    int likesCount = widget.snap['likes'] ?? 0;
    if (isLiked) likesCount += 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$likesCount lượt thích',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 8),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: '${widget.snap['username'] ?? 'username'} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.snap['description'] ?? 'Giao diện mượt thế này 10 điểm! 🚀',
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'View all 200 comments',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              '2 DAYS AGO', // Sẽ thay bằng hàm format thời gian sau
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}