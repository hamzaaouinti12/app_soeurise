import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';

class PostSettingsScreen extends StatefulWidget {
  final Post post;

  const PostSettingsScreen({super.key, required this.post});

  @override
  State<PostSettingsScreen> createState() => _PostSettingsScreenState();
}

class _PostSettingsScreenState extends State<PostSettingsScreen> {
  bool _busy = false;

  bool get _isOwner =>
      widget.post.authorId.isNotEmpty &&
      widget.post.authorId == ProfileService.instance.profile.value.id;

  Future<void> _toggleComments() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await PostService.instance.toggleCommentsDisabled(widget.post.id);
    if (mounted) {
      setState(() => _busy = false);
      if (ok) {
        setState(() {
          widget.post.commentsDisabled = !widget.post.commentsDisabled;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action impossible')),
        );
      }
    }
  }

  Future<void> _togglePin() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await PostService.instance.togglePinPost(widget.post.id);
    if (mounted) {
      setState(() => _busy = false);
      if (ok) {
        setState(() {
          widget.post.isPinned = !widget.post.isPinned;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action impossible')),
        );
      }
    }
  }

  Future<void> _editPost() async {
    final controller = TextEditingController(text: widget.post.content);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Votre texte...'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (updated == null || updated.isEmpty || _busy) return;
    setState(() => _busy = true);
    final post = await PostService.instance.updatePost(
      widget.post.id,
      content: updated,
    );
    if (mounted) {
      setState(() => _busy = false);
      if (post != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication mise a jour')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise a jour')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await PostService.instance.deletePost(widget.post.id);
    if (mounted) {
      setState(() => _busy = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Parametres du post',
          style: AppTextStyles.headline3.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              children: [
                if (_isOwner)
                  ListTile(
                    leading: Icon(
                      widget.post.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      widget.post.isPinned ? 'Desepingler' : 'Epingler',
                      style: AppTextStyles.bodyLarge,
                    ),
                    onTap: _busy ? null : _togglePin,
                  ),
                if (_isOwner)
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: Text('Modifier la publication', style: AppTextStyles.bodyLarge),
                    onTap: _busy ? null : _editPost,
                  ),
                if (_isOwner)
                  Divider(color: AppColors.beigeDark.withAlpha(40), height: 1),
                if (_isOwner)
                  ListTile(
                    leading: Icon(
                      widget.post.commentsDisabled
                          ? Icons.comment_rounded
                          : Icons.comments_disabled_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      widget.post.commentsDisabled
                          ? 'Activer les commentaires'
                          : 'Desactiver les commentaires',
                      style: AppTextStyles.bodyLarge,
                    ),
                    onTap: _busy ? null : _toggleComments,
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, color: Colors.red),
                    title: Text('Signaler', style: AppTextStyles.bodyLarge),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signalement envoye')),
                      );
                    },
                  ),
                Divider(color: AppColors.beigeDark.withAlpha(40), height: 1),
                if (_isOwner)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    title: Text('Supprimer', style: AppTextStyles.bodyLarge),
                    onTap: _deletePost,
                  ),
              ],
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
