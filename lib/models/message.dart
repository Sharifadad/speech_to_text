// TODO Implement this library.
class Message {
  final String sender;
  final String avatar;
  final String content;
  final String time;
  final bool isFollowBack;
  final bool isVerified;

  Message({
    required this.sender,
    required this.avatar,
    required this.content,
    required this.time,
    this.isFollowBack = false,
    this.isVerified = false,
  });
}