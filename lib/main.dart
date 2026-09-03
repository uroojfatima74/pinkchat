import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PinkChatApp());
}

class PinkChatApp extends StatelessWidget {
  const PinkChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PinkChat',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF1493),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  String userName = "Mee";
  File? userImage;

  void _updateProfile(String newName, File? newImage) {
    setState(() {
      userName = newName;
      if (newImage != null) userImage = newImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ChatListScreen(userName: userName, userImage: userImage),
      ProfileScreen(
        currentName: userName,
        currentImage: userImage,
        onSave: _updateProfile,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF1493),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  final String userName;
  final File? userImage;
  const ChatListScreen({super.key, required this.userName, this.userImage});

  final List<Map<String, String>> chats = const [
    {'name': 'Ayesha', 'message': 'Hey! How are you?', 'time': '10:30 AM'},
    {'name': 'Mom', 'message': 'Khana kha liya?', 'time': '09:15 AM'},
    {'name': 'Sana', 'message': 'See you tomorrow!', 'time': 'Yesterday'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PinkChat ($userName)'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF69B4),
              child: Text(chat['name']![0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(chat['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chat['message']!),
            trailing: Text(chat['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailChatScreen(userName: chat['name']!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailChatScreen extends StatefulWidget {
  final String userName;
  const DetailChatScreen({super.key, required this.userName});

  @override
  State<DetailChatScreen> createState() => _DetailChatScreenState();
}

class _DetailChatScreenState extends State<DetailChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hey there!', 'isAudio': false, 'isMe': false},
  ];
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      String path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      setState(() {
        messages.add({'text': path, 'isAudio': true, 'isMe': true});
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        messages.add({'text': _controller.text.trim(), 'isAudio': false, 'isMe': true});
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg['isMe'];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFF69B4) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: msg['isAudio']
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.white),
                                onPressed: () => _audioPlayer.play(DeviceFileSource(msg['text'])),
                              ),
                              const Text('Voice Note', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: const Color(0xFFFF1493)),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFF1493)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String currentName;
  final File? currentImage;
  final Function(String, File?) onSave;

  const ProfileScreen({super.key, required this.currentName, this.currentImage, required this.onSave});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _image = widget.currentImage;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFFF69B4),
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1493)),
              onPressed: () {
                widget.onSave(_nameController.text, _image);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
              },
              child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
