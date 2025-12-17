import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatService {
  static const String baseUrl =
      "https://chat-backend-2-q2i3.onrender.com";

  static late io.Socket socket;

  // ---------------- CONNECT ----------------
  static void connect() {
    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect() // ✅ important
          .build(),
    );

    socket.onConnect((_) {
      debugPrint("✅ Socket connected");
    });

    socket.onDisconnect((_) {
      debugPrint("❌ Socket disconnected");
    });

    socket.onConnectError((err) {
      debugPrint("⚠️ Socket connect error: $err");
    });
  }

  // ---------------- JOIN ROOM ----------------
  static void joinRoom(String room) {
    socket.emit("join", {"room": room});
  }

  // ---------------- SEND MESSAGE ----------------
  static void sendMessage(
    String room,
    int senderId,
    int receiverId,
    String message,
  ) {
    socket.emit("send_message", {
      "room": room,
      "sender_id": senderId,
      "receiver_id": receiverId,
      "message": message,
    });
  }

  // ---------------- LOAD OLD MESSAGES ----------------
  static Future<List<dynamic>> fetchMessages(String room) async {
    final res = await http.get(
      Uri.parse("$baseUrl/messages/$room"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      debugPrint("❌ Failed to load messages");
      return [];
    }
  }
}
