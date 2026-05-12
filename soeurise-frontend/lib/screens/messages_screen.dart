import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import '../widgets/user_avatar.dart';
import '../theme/glass_widgets.dart';
import 'private_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageService = MessageService.instance;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription? _msgSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _readSub;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _listenRealtime();
  }

  void _listenRealtime() {
    _msgSub = SocketService().messageStream.listen((_) {
      _loadConversations(silent: true);
    });
    _deleteSub = SocketService().deleteStream.listen((_) {
      _loadConversations(silent: true);
    });
    _readSub = SocketService().readStream.listen((_) {
      _loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _deleteSub?.cancel();
    _readSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    final list = await _messageService.fetchConversations();
    if (mounted) {
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    }
  }

  String _formatPreview(PrivateMessage msg) {
    if (msg.deletedForAll) return 'Message supprime';
    if (msg.storyImageUrl != null && msg.storyImageUrl!.isNotEmpty) {
      return 'Reponse a votre story: ${msg.text}';
    }
    if (msg.type == 'image') return '[Photo]';
    if (msg.type == 'audio') return '[Audio]';
    return msg.text.isNotEmpty ? msg.text : 'Message';
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Messages', style: AppTextStyles.headline3.copyWith(fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadConversations,
              color: AppColors.primary,
              child: _conversations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.message_outlined, size: 56, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Aucune conversation',
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      itemBuilder: (context, i) {
                        final conv = _conversations[i];
                        final user = conv.user;
                        final last = conv.lastMessage;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PrivateChatScreen(user: user),
                                  ),
                                ).then((_) => _loadConversations(silent: true));
                              },
                              child: Row(
                                children: [
                                  UserAvatar(
                                    imageUrl: user.avatarFullUrl.isNotEmpty ? user.avatarFullUrl : null,
                                    username: user.fullName.isNotEmpty ? user.fullName : user.username,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName.trim().isNotEmpty ? user.fullName : user.username,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatPreview(last),
                                          style: AppTextStyles.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTime(last.createdAt),
                                        style: AppTextStyles.caption,
                                      ),
                                      if (conv.unreadCount > 0) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${conv.unreadCount}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
