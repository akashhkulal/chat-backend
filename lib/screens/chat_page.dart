import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final int myId;
  final int otherUserId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.myId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageCtrl = TextEditingController();
  List<dynamic> messages = [];

  late final String roomId;

  @override
  void initState() {
    super.initState();

    // 🔑 Create unique room ID
    roomId = widget.myId < widget.otherUserId
        ? "${widget.myId}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.myId}";

    // 🔌 Connect socket
    ChatService.connect();

    // 🔥 Listen for incoming messages FIRST
    ChatService.socket.on("receive_message", (data) {
      if (!mounted) return;
      setState(() {
        messages.add(data);
      });
    });

    // 🚪 Join chat room
    ChatService.joinRoom(roomId);

    // 📦 Load old messages from backend
    loadOldMessages();
  }

  // 📥 Load stored messages
  Future<void> loadOldMessages() async {
    final oldMessages = await ChatService.fetchMessages(roomId);
    if (!mounted) return;
    setState(() {
      messages = oldMessages;
    });
  }

  // 📤 Send message (NO local add)
  void sendMessage() {
    if (messageCtrl.text.trim().isEmpty) return;

    ChatService.sendMessage(
      roomId,
      widget.myId,
      widget.otherUserId,
      messageCtrl.text.trim(),
    );

    messageCtrl.clear();
  }

  @override
  void dispose() {
    messageCtrl.dispose();
    ChatService.socket.off("receive_message");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["sender_id"] == widget.myId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isMe ? Colors.blueAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["message"],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageCtrl,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
