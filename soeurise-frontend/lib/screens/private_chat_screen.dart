import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/message_service.dart';
import '../services/profile_service.dart';
import '../services/socket_service.dart';
import '../widgets/adaptive_image.dart';
import '../widgets/user_avatar.dart';

class PrivateChatScreen extends StatefulWidget {
  final User user;

  const PrivateChatScreen({super.key, required this.user});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _messageService = MessageService.instance;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  late AudioRecorder _recorder;  // Will be initialized in initState
  final _audioPlayer = AudioPlayer();

  List<PrivateMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _isRecording = false;
  String? _pendingMediaPath;
  String? _pendingMediaType; // image | audio

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _editedSub;
  StreamSubscription? _reactedSub;
  Timer? _typingTimer;

  PrivateMessage? _replyingTo;
  PrivateMessage? _editingMessage;

  String get _currentUserId => ProfileService.instance.profile.value.id;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _messages = _messageService.getCachedChat(widget.user.id);
    _loadMessages();
    _listenSockets();
    _controller.addListener(_onTyping); 
  }

  @override
  void dispose() {
    _controller.removeListener(_onTyping);
    _controller.dispose();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _deleteSub?.cancel();
    _editedSub?.cancel();
    _reactedSub?.cancel();
    _typingTimer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    // Only show full loading if we have no cached messages
    if (_messages.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    final list = await _messageService.fetchChat(widget.user.id);
    
    if (mounted) {
      setState(() {
        if (list != null) {
          _messages = list;
        }
        _isLoading = false;
      });
      _scrollToBottom();
    }
    await _messageService.markChatRead(widget.user.id);
  }

  void _listenSockets() {
    _msgSub = SocketService().messageStream.listen((data) {
      final msg = PrivateMessage.fromJson(data as Map<String, dynamic>);
      final isForThisChat =
          (msg.senderId == widget.user.id && msg.recipientId == _currentUserId) ||
          (msg.senderId == _currentUserId && msg.recipientId == widget.user.id);
      if (!isForThisChat) return;
      if (mounted) {
        setState(() {
          final exists = _messages.any((m) => 
            (m.id.isNotEmpty && m.id == msg.id) ||
            (m.senderId == msg.senderId && m.text == msg.text && (m.createdAt.difference(msg.createdAt).inSeconds.abs() < 5))
          );
          if (!exists) {
            _messages = [..._messages, msg];
            _messageService.addMessageFromSocket(widget.user.id, msg);
            _scrollToBottom();
          }
        });
      }
      if (msg.senderId == widget.user.id) {
        _messageService.markChatRead(widget.user.id);
      }
    });

    _typingSub = SocketService().typingStream.listen((data) {
      if (data is! Map) return;
      final stop = data['stop'] == true;
      final payload = stop ? data['data'] : data;
      final fromUserId = payload?['fromUserId']?.toString();
      if (fromUserId != widget.user.id) return;
      if (mounted) setState(() => _isTyping = !stop);
    });

    _readSub = SocketService().readStream.listen((data) {
      if (data is! Map) return;
      final readerId = data['readerId']?.toString();
      if (readerId != widget.user.id) return;
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.senderId == _currentUserId) {
              return m.copyWith(isRead: true);
            }
            return m;
          }).toList();
        });
      }
    });

    _deleteSub = SocketService().deleteStream.listen((data) {
      if (data is! Map) return;
      final messageId = data['messageId']?.toString();
      if (messageId == null) return;
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == messageId) {
              return m.copyWith(deletedForAll: true, text: '', mediaUrl: '');
            }
            return m;
          }).toList();
        });
      }
    });

    _editedSub = SocketService().messageEditedStream.listen((data) {
      if (data is! Map) return;
      final msg = PrivateMessage.fromJson(data as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            _messages[index] = msg;
          }
        });
      }
    });

    _reactedSub = SocketService().messageReactedStream.listen((data) {
      if (data is! Map) return;
      final msg = PrivateMessage.fromJson(data as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            _messages[index] = msg;
          }
        });
      }
    });
  }

  void _onTyping() {
    if (_controller.text.trim().isEmpty) return;
    SocketService().sendTyping(widget.user.id, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      SocketService().sendTyping(widget.user.id, false);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1400);
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _pendingMediaPath = picked.path;
        _pendingMediaType = 'image';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() {
          _pendingMediaPath = path;
          _pendingMediaType = 'audio';
        });
      }
      return;
    }

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) return;
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingMediaPath == null) return;

    setState(() => _isSending = true);
    PrivateMessage? msg;

    if (_editingMessage != null) {
      msg = await _messageService.editMessage(_editingMessage!.id, text);
      if (msg != null && mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg!.id);
          if (idx != -1) _messages[idx] = msg!;
          _editingMessage = null;
          _controller.clear();
        });
      }
    } else {
      if (_pendingMediaPath != null) {
        msg = await _messageService.sendMediaMessage(
          widget.user.id,
          _pendingMediaPath!,
          text: text.isNotEmpty ? text : null,
          audioDurationMs: null,
          replyToId: _replyingTo?.id,
        );
      } else {
        msg = await _messageService.sendTextMessage(widget.user.id, text, replyToId: _replyingTo?.id);
      }

      if (msg != null && mounted) {
        setState(() {
          final exists = _messages.any((m) => 
            (m.id.isNotEmpty && m.id == msg!.id) ||
            (m.senderId == msg!.senderId && m.text == msg!.text && m.mediaUrl == msg!.mediaUrl && (m.createdAt.difference(msg!.createdAt).inSeconds.abs() < 5))
          );
          if (!exists) {
            _messages = [..._messages, msg!];
            _scrollToBottom();
          }
          _pendingMediaPath = null;
          _pendingMediaType = null;
          _replyingTo = null;
          _controller.clear();
        });
      }
    }

    SocketService().sendTyping(widget.user.id, false);
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _playAudio(PrivateMessage msg) async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setUrl(msg.mediaUrl);
      await _audioPlayer.play();
    } catch (_) {}
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteMessage(PrivateMessage msg) async {
    final ok = await MessageService.instance.deleteMessage(msg.id);
    if (ok && mounted) {
      setState(() {
        _messages = _messages.map((m) {
          if (m.id == msg.id) {
            return m.copyWith(deletedForAll: true, text: '', mediaUrl: '');
          }
          return m;
        }).toList();
      });
    }
  }

  void _showContextMenu(PrivateMessage msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Répondre'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = msg);
                },
              ),
              if (isMe && msg.type == 'text')
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _editingMessage = msg;
                      _controller.text = msg.text;
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: const Text('Réagir'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReactionMenu(msg);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionMenu(PrivateMessage msg) {
    final emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: emojis.map((e) => GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              final updated = await MessageService.instance.reactToMessage(msg.id, e);
              if (updated != null && mounted) {
                setState(() {
                  final idx = _messages.indexWhere((m) => m.id == msg.id);
                  if (idx != -1) _messages[idx] = updated;
                });
              }
            },
            child: Text(e, style: const TextStyle(fontSize: 28)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PrivateMessage msg, bool isMe, bool isLastOutgoing) {
    final bg = isMe ? AppColors.primary : Colors.white;
    final fg = isMe ? Colors.white : AppColors.textPrimary;

    String time = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    Widget content;
    if (msg.deletedForAll) {
      content = Text(
        'Message supprime',
        style: TextStyle(color: fg.withAlpha(160), fontSize: 12, fontStyle: FontStyle.italic),
      );
    } else if (msg.type == 'image' && msg.mediaUrl.isNotEmpty) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          msg.mediaUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else if (msg.type == 'audio' && msg.mediaUrl.isNotEmpty) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: fg),
          const SizedBox(width: 6),
          Text('Audio', style: TextStyle(color: fg)),
        ],
      );
    } else {
      content = Text(msg.text, style: TextStyle(color: fg, fontSize: 14));
    }

    return GestureDetector(
      onLongPress: !msg.deletedForAll ? () => _showContextMenu(msg, isMe) : null,
      onTap: msg.type == 'audio' && msg.mediaUrl.isNotEmpty ? () => _playAudio(msg) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? AppColors.primary : Colors.black).withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.storyImageUrl != null && msg.storyImageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              msg.storyImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
                            child: Icon(
                              Icons.south_rounded,
                              size: 14,
                              color: fg.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (msg.replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : AppColors.beigeDark).withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: isMe ? Colors.white70 : AppColors.primary, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reponse a ${msg.replyTo!.senderId == _currentUserId ? 'Vous' : widget.user.username}',
                            style: TextStyle(color: fg.withAlpha(200), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.replyTo!.text.isNotEmpty ? msg.replyTo!.text : 'Piece jointe',
                            style: TextStyle(color: fg.withAlpha(200), fontSize: 12, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  content,
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(color: fg.withAlpha(160), fontSize: 10),
                      ),
                      if (msg.isEdited) ...[
                        const SizedBox(width: 4),
                        Text('(Modifie)', style: TextStyle(color: fg.withAlpha(160), fontSize: 10, fontStyle: FontStyle.italic)),
                      ],
                      if (isMe && isLastOutgoing && msg.isRead) ...[
                        const SizedBox(width: 6),
                        Text('Vu', style: TextStyle(color: fg.withAlpha(180), fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (msg.reactions.isNotEmpty)
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 2, left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: msg.reactions.map((r) => Text(r['reactionType'] as String, style: const TextStyle(fontSize: 10))).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastOutgoingIndex = _messages.lastIndexWhere((m) => m.senderId == _currentUserId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 8,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                UserAvatar(
                  imageUrl: widget.user.avatarFullUrl.isNotEmpty ? widget.user.avatarFullUrl : null,
                  username: widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.username,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.username,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isTyping ? 'En train d\'ecrire...' : 'En ligne',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      final isLastOutgoing = index == lastOutgoingIndex;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: _buildMessageBubble(msg, isMe, isLastOutgoing),
                      );
                    },
                  ),
          ),

          if (_pendingMediaPath != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  if (_pendingMediaType == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AdaptiveImage(
                        localPath: _pendingMediaPath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.mic_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pendingMediaType == 'image' ? 'Image prete a envoyer' : 'Audio pret a envoyer',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _pendingMediaPath = null;
                      _pendingMediaType = null;
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

          if (_replyingTo != null || _editingMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.beigeDark.withAlpha(40),
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit_rounded : Icons.reply_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingMessage != null ? 'Modification du message' : 'Reponse a un message',
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          _editingMessage != null ? _editingMessage!.text : (_replyingTo!.text.isNotEmpty ? _replyingTo!.text : 'Media'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _replyingTo = null;
                      _editingMessage = null;
                      _controller.clear();
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.beigeDark.withAlpha(40))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library_rounded),
                              title: const Text('Galerie'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded),
                              title: const Text('Camera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppColors.primary,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _isRecording ? 'Enregistrement en cours...' : 'Votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.beigeDark.withAlpha(60)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.beigeDark.withAlpha(60)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isRecording ? Colors.white : AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
