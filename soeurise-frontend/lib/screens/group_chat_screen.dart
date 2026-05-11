import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../constants.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../services/socket_service.dart';
import '../theme/glass_widgets.dart';

class GroupChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const GroupChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late final ValueNotifier<List<ChatMessage>> messages;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final AudioRecorder _recorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isSending = false;
  File? _pendingMedia;
  String? _pendingMediaType; // image | audio
  StreamSubscription? _msgSubscription;

  @override
  void initState() {
    super.initState();
    messages = CommunityService.instance.messagesFor(widget.communityId);
    _loadMessages();
    _recorder = AudioRecorder();

    SocketService().joinGroup(widget.communityId);
    _msgSubscription = SocketService().groupMessageStream.listen((data) {
      if (data['groupId'] == widget.communityId) {
        CommunityService.instance.addMessageFromSocket(widget.communityId, data);
      }
    });
  }

  Future<void> _loadMessages() async {
    await CommunityService.instance.fetchMessages(widget.communityId);
  }

  @override
  void dispose() {
    SocketService().leaveGroup(widget.communityId);
    _msgSubscription?.cancel();
    _controller.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _pendingMedia = File(picked.path);
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
          _pendingMedia = File(path);
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
    if (text.isEmpty && _pendingMedia == null) return;

    setState(() => _isSending = true);
    bool ok = false;

    if (_pendingMedia != null) {
      ok = await CommunityService.instance.sendMediaMessage(
        widget.communityId,
        _pendingMedia!,
        text: text.isNotEmpty ? text : null,
        audioDurationMs: null,
      );
    } else {
      ok = await CommunityService.instance.sendMessage(
        widget.communityId,
        text,
      );
    }

    if (ok && mounted) {
      setState(() {
        _pendingMedia = null;
        _pendingMediaType = null;
        _controller.clear();
      });
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _playAudio(ChatMessage msg) async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setUrl(msg.mediaUrl);
      await _audioPlayer.play();
    } catch (_) {}
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final fg = isMe ? Colors.white : AppColors.textPrimary;
    final time =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    Widget content;
    if (msg.type == 'image' && msg.mediaUrl.isNotEmpty) {
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
      onTap: msg.type == 'audio' && msg.mediaUrl.isNotEmpty
          ? () => _playAudio(msg)
          : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
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
            content,
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: fg.withAlpha(160), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(50),
                  ),
                  child: Center(
                    child: Text(
                      widget.communityName.isNotEmpty
                          ? widget.communityName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.communityName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'En ligne',
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
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: messages,
              builder: (context, msgs, _) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.primary.withAlpha(100),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Aucun message', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Soyez la premiere a ecrire !',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final currentUser = ProfileService.instance.profile.value;
                    final m = msgs[index];
                    final isMe = m.senderId == currentUser.id;

                    return FadeSlideIn(
                      delay: Duration(milliseconds: index * 50),
                      offset: Offset(isMe ? 20 : -20, 0),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.primary.withAlpha(30),
                                backgroundImage: m.senderAvatar.isNotEmpty
                                    ? NetworkImage(
                                        ApiConfig.uploadsUrl(m.senderAvatar),
                                      )
                                    : null,
                                child: m.senderAvatar.isEmpty
                                    ? Text(
                                        m.sender.isNotEmpty
                                            ? m.sender[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        m.sender,
                                        style:
                                            AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  _buildMessageBubble(m, isMe),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_pendingMedia != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  if (_pendingMediaType == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _pendingMedia!,
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
                      _pendingMediaType == 'image'
                          ? 'Image prete a envoyer'
                          : 'Audio pret a envoyer',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _pendingMedia = null;
                      _pendingMediaType = null;
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.beigeDark.withAlpha(40),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
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
                                    leading:
                                        const Icon(Icons.photo_library_rounded),
                                    title: const Text('Galerie'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.camera_alt_rounded),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.beigeLight,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xl),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: _isRecording
                                  ? 'Enregistrement en cours...'
                                  : 'Ecrire un message...',
                              hintStyle: AppTextStyles.bodySmall,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(50),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.red
                                : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                            ),
                          ),
                          child: Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: _isRecording
                                ? Colors.white
                                : AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
