import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';
import 'api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _messageController = StreamController<dynamic>.broadcast();
  final _notificationController = StreamController<dynamic>.broadcast();
  final _groupMessageController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<dynamic>.broadcast();
  final _readController = StreamController<dynamic>.broadcast();
  final _deleteController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get notificationStream => _notificationController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<dynamic> get groupMessageStream => _groupMessageController.stream;
  Stream<dynamic> get typingStream => _typingController.stream;
  Stream<dynamic> get readStream => _readController.stream;
  Stream<dynamic> get deleteStream => _deleteController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> init() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) return;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = IO.io(ApiConfig.serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) {
      print('[Socket] Connected to server');
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected from server');
    });

    _socket!.onConnectError((err) {
      print('[Socket] Connect error: $err');
    });

    // Listen for events
    _socket!.on('new_notification', (data) {
      print('[Socket] New notification: $data');
      _notificationController.add(data);
    });

    _socket!.on('new_private_message', (data) {
      print('[Socket] New private message: $data');
      _messageController.add(data);
    });

    _socket!.on('new_group_message', (data) {
      print('[Socket] New group message: $data');
      _groupMessageController.add(data);
    });

    _socket!.on('private_typing', (data) {
      _typingController.add(data);
    });

    _socket!.on('private_stop_typing', (data) {
      _typingController.add({'stop': true, 'data': data});
    });

    _socket!.on('private_messages_read', (data) {
      _readController.add(data);
    });

    _socket!.on('private_message_deleted', (data) {
      _deleteController.add(data);
    });
  }

  void joinGroup(String groupId) {
    if (_socket != null && isConnected) {
      _socket!.emit('join_room', 'group_$groupId');
    }
  }

  void leaveGroup(String groupId) {
    if (_socket != null && isConnected) {
      _socket!.emit('leave_room', 'group_$groupId');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void sendTyping(String toUserId, bool isTyping) {
    if (_socket == null || !isConnected) return;
    final event = isTyping ? 'private_typing' : 'private_stop_typing';
    _socket!.emit(event, {'toUserId': toUserId});
  }
}
