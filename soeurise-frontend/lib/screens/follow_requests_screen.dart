import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/user_avatar.dart';

/// Demandes d'abonnement reçues (compte privé).
class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  List<User> _requests = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ProfileService.instance.fetchIncomingFollowRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  Future<void> _accept(User u) async {
    _busy.add(u.id);
    setState(() {});
    await ProfileService.instance.acceptFollowRequest(u.id);
    _busy.remove(u.id);
    await _load();
  }

  Future<void> _decline(User u) async {
    _busy.add(u.id);
    setState(() {});
    await ProfileService.instance.declineFollowRequest(u.id);
    _busy.remove(u.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Demandes d\'abonnement', style: AppTextStyles.headline3.copyWith(fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child:
                    _requests.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 56,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Aucune demande en attente',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, i) {
                            final u = _requests[i];
                            final busy = _busy.contains(u.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      imageUrl: u.avatarFullUrl.isNotEmpty ? u.avatarFullUrl : null,
                                      username: u.fullName,
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.fullName.trim().isNotEmpty ? u.fullName : u.username,
                                            style: AppTextStyles.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '@${u.username}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (busy)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    else ...[
                                      TextButton(
                                        onPressed: () => _decline(u),
                                        child: const Text('Refuser'),
                                      ),
                                      const SizedBox(width: 4),
                                      FilledButton(
                                        onPressed: () => _accept(u),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                        ),
                                        child: const Text('Accepter'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
