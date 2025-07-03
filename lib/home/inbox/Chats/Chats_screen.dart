import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientPhotoUrl;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoUrl, required String chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late String _currentUserId;
  late String _chatId;
  bool _isUploading = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // For reply functionality
  Map<String, dynamic>? _replyingToMessage;
  bool _showReplyPreview = false;

  // For voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _chatId = _currentUserId.compareTo(widget.recipientId) < 0
        ? '${_currentUserId}_${widget.recipientId}'
        : '${widget.recipientId}_${_currentUserId}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _stopRecording();
    super.dispose();
  }

  Future<void> _sendMessage({String? text, String? mediaUrl, String? mediaType}) async {
    if ((text == null || text.isEmpty) && (mediaUrl == null || mediaType == null)) {
      return;
    }

    try {
      final messageData = {
        'senderId': _currentUserId,
        'recipientId': widget.recipientId,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add reply data if replying to a message
      if (_replyingToMessage != null) {
        messageData['replyTo'] = {
          'messageId': _replyingToMessage!['id'],
          'senderId': _replyingToMessage!['senderId'],
          'text': _replyingToMessage!['text'] ??
              (_replyingToMessage!['mediaType'] == 'image' ? 'Photo' :
              _replyingToMessage!['mediaType'] == 'video' ? 'Video' :
              _replyingToMessage!['mediaType'] == 'audio' ? 'Voice message' : 'File'),
          'mediaType': _replyingToMessage!['mediaType'],
        };
      }

      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(messageData);

      // Update the last message in the chats collection
      await _firestore.collection('chats').doc(_chatId).set({
        'lastMessage': text ?? '[${mediaType == 'image' ? 'Photo' : mediaType == 'video' ? 'Video' : mediaType == 'audio' ? 'Voice message' : 'File'}]',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'participants': [_currentUserId, widget.recipientId],
      }, SetOptions(merge: true));

      // Clear reply after sending
      if (_replyingToMessage != null) {
        setState(() {
          _replyingToMessage = null;
          _showReplyPreview = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _pickAndSendImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final file = File(pickedFile.path);
      final ref = _storage.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(mediaUrl: downloadUrl, mediaType: 'image');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final file = File(pickedFile.path);
      final ref = _storage.ref().child('chat_videos/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(mediaUrl: downloadUrl, mediaType: 'video');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send video: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      setState(() => _isUploading = true);
      final file = File(result.files.single.path!);
      final ref = _storage.ref().child('chat_files/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(mediaUrl: downloadUrl, mediaType: 'file');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        setState(() => _isRecording = false);

        if (_recordingPath != null) {
          setState(() => _isUploading = true);
          final file = File(_recordingPath!);
          final ref = _storage.ref().child('chat_audio/${DateTime.now().millisecondsSinceEpoch}');
          final uploadTask = ref.putFile(file);
          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();

          await _sendMessage(mediaUrl: downloadUrl, mediaType: 'audio');
          await file.delete(); // Clean up temporary file
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _recordingPath = null;
      });
    }
  }

  Future<void> _playAudio(String url, String messageId) async {
    if (_isPlaying && _currentlyPlayingId == messageId) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = null;
      });
    } else {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentlyPlayingId = messageId;
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
      });
    }
  }

  String _getVideoThumbnailUrl(String videoUrl) {
    return 'https://via.placeholder.com/150';
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting voice call...')),
    );
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting video call...')),
    );
  }

  Widget _buildReplyPreview() {
    if (!_showReplyPreview || _replyingToMessage == null) return const SizedBox();

    final isMe = _replyingToMessage!['senderId'] == _currentUserId;
    final senderName = isMe ? 'You' : widget.recipientName;
    final replyText = _replyingToMessage!['text'] ??
        (_replyingToMessage!['mediaType'] == 'image' ? 'Photo' :
        _replyingToMessage!['mediaType'] == 'video' ? 'Video' :
        _replyingToMessage!['mediaType'] == 'audio' ? 'Voice message' : 'File');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: const Color(0xFF075E54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to $senderName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replyText.length > 30 ? '${replyText.substring(0, 30)}...' : replyText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
                _showReplyPreview = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot messageDoc, bool isMe) {
    final message = messageDoc.data() as Map<String, dynamic>;
    final time = message['timestamp'] != null
        ? TimeOfDay.fromDateTime(message['timestamp'].toDate()).format(context)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply preview if this message is a reply
          if (message['replyTo'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replying to ${message['replyTo']['senderId'] == _currentUserId ? 'You' : widget.recipientName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['replyTo']['text'] ??
                        (message['replyTo']['mediaType'] == 'image' ? 'Photo' :
                        message['replyTo']['mediaType'] == 'video' ? 'Video' :
                        message['replyTo']['mediaType'] == 'audio' ? 'Voice message' : 'File'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          GestureDetector(
            onLongPress: () {
              setState(() {
                _replyingToMessage = {
                  ...message,
                  'id': messageDoc.id,
                };
                _showReplyPreview = true;
                _focusNode.requestFocus();
              });
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['text'] != null)
                    Text(
                      message['text'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  if (message['mediaUrl'] != null)
                    _buildMediaMessage(message, messageDoc.id),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isMe)
                const SizedBox(width: 4),
              if (isMe)
                Icon(
                  Icons.done_all,
                  size: 16,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(Map<String, dynamic> message, String messageId) {
    switch (message['mediaType']) {
      case 'image':
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 250,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message['mediaUrl'],
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'video':
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 250,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.network(
                  _getVideoThumbnailUrl(message['mediaUrl']),
                  fit: BoxFit.cover,
                  width: 250,
                  height: 250,
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'audio':
        return GestureDetector(
          onTap: () => _playAudio(message['mediaUrl'], messageId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPlaying && _currentlyPlayingId == messageId
                      ? Icons.stop
                      : Icons.play_arrow,
                  color: const Color(0xFF075E54),
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice message',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.audiotrack,
                  color: Color(0xFF075E54),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      case 'file':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 40),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'PDF File',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Row(
          children: [
            if (widget.recipientPhotoUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.recipientPhotoUrl!),
                radius: 16,
              )
            else
              CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 16,
                child: Text(
                  widget.recipientName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              widget.recipientName,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: _startVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: _startVideoCall,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final messageData = message.data() as Map<String, dynamic>;
                        final isMe = messageData['senderId'] == _currentUserId;

                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
            ),
            if (_isUploading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF075E54),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF128C7E)),
              ),
            if (_showReplyPreview) _buildReplyPreview(),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndSendImage(fromCamera: true);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.image),
                                title: const Text('Photo & Video'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndSendImage();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.video_library),
                                title: const Text('Video'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndSendVideo();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: const Text('Document'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndSendFile();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 0,
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (text) {
                                _sendMessage(text: text.trim());
                                _messageController.clear();
                              },
                            ),
                          ),
                          GestureDetector(
                            onLongPressStart: (_) => _startRecording(),
                            onLongPressEnd: (_) => _stopRecording(),
                            child: IconButton(
                              icon: Icon(
                                _isRecording ? Icons.mic_off : Icons.mic,
                                color: _isRecording ? Colors.red : Colors.grey,
                              ),
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        _sendMessage(text: _messageController.text.trim());
                        _messageController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}