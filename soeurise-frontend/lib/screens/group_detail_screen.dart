import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/community_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/user_avatar.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final bool isPublic;
  final int memberCount;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.isPublic,
    required this.memberCount,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GroupMember> _members = [];
  bool _isLoadingMembers = true;
  bool _isAdmin = false;

  // Edit form
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late bool _isPublicEdit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController(text: widget.groupName);
    _descCtrl = TextEditingController(text: widget.groupDescription);
    _isPublicEdit = widget.isPublic;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingMembers = true);
    final results = await Future.wait([
      CommunityService.instance.fetchGroupMembers(widget.groupId),
      CommunityService.instance.getMyRole(widget.groupId),
    ]);
    final members = results[0] as List<GroupMember>;
    final role = results[1] as String;
    if (mounted) {
      setState(() {
        _members = members;
        _isAdmin = role == 'owner' || role == 'moderator';
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _saveGroupInfo() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Le nom du groupe ne peut pas être vide');
      return;
    }
    setState(() => _isSaving = true);
    final ok = await CommunityService.instance.updateGroupInfo(
      widget.groupId,
      name: name,
      description: desc,
      isPublic: _isPublicEdit,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      _showSuccess('Groupe mis à jour avec succès');
      // Pop with true to signal parent to refresh
      Navigator.pop(context, true);
    } else {
      _showError('Impossible de mettre à jour le groupe');
    }
  }

  Future<void> _changeRole(GroupMember member) async {
    if (member.isOwner) {
      _showError('Impossible de modifier le rôle du propriétaire');
      return;
    }
    final newRole = member.isModerator ? 'member' : 'moderator';
    final label = member.isModerator ? 'membre' : 'modérateur';

    final confirmed = await _confirm(
      'Changer le rôle',
      'Définir ${member.fullName} comme $label ?',
    );
    if (!confirmed) return;

    final ok = await CommunityService.instance.updateMemberRole(
      widget.groupId,
      member.id,
      newRole,
    );
    if (!mounted) return;
    if (ok) {
      _showSuccess('Rôle mis à jour');
      await _loadData();
    } else {
      _showError('Erreur lors du changement de rôle');
    }
  }

  Future<void> _kickMember(GroupMember member) async {
    if (member.isOwner) {
      _showError('Impossible d\'expulser le propriétaire du groupe');
      return;
    }
    final confirmed = await _confirm(
      'Expulser le membre',
      'Voulez-vous retirer ${member.fullName} du groupe ?',
    );
    if (!confirmed) return;

    final ok = await CommunityService.instance.kickMember(
      widget.groupId,
      member.id,
    );
    if (!mounted) return;
    if (ok) {
      _showSuccess('Membre retiré du groupe');
      await _loadData();
    } else {
      _showError('Impossible de retirer ce membre');
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        title: Text(title, style: AppTextStyles.headline4),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmer',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.successColor,
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.errorColor,
    ));
  }

  // ─── Role badge ────────────────────────────────────────────────────────────

  Widget _roleBadge(String role) {
    final Map<String, Map<String, dynamic>> config = {
      'owner': {
        'label': 'Propriétaire',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFFFB300),
      },
      'moderator': {
        'label': 'Modérateur',
        'icon': Icons.verified_rounded,
        'color': AppColors.primary,
      },
      'member': {
        'label': 'Membre',
        'icon': Icons.person_rounded,
        'color': AppColors.textLight,
      },
    };
    final c = config[role] ?? config['member']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: (c['color'] as Color).withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c['icon'] as IconData, size: 12, color: c['color'] as Color),
          const SizedBox(width: 4),
          Text(
            c['label'] as String,
            style: AppTextStyles.caption.copyWith(
              color: c['color'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Members Tab ───────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    if (_isLoadingMembers) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_members.isEmpty) {
      return Center(
        child: Text('Aucun membre', style: AppTextStyles.bodyMedium),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final m = _members[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: index * 40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl:
                        m.avatarUrl.isNotEmpty ? m.avatarFullUrl : null,
                    radius: 22,
                    username: m.fullName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fullName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${m.username}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _roleBadge(m.roleInGroup),
                  // Admin actions
                  if (_isAdmin && !m.isOwner) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      onSelected: (val) {
                        if (val == 'role') _changeRole(m);
                        if (val == 'kick') _kickMember(m);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(
                                m.isModerator
                                    ? Icons.person_rounded
                                    : Icons.verified_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                m.isModerator
                                    ? 'Rétrograder en membre'
                                    : 'Promouvoir modérateur',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'kick',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_remove_rounded,
                                size: 16,
                                color: AppColors.errorColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expulser',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.errorColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Admin Tab ─────────────────────────────────────────────────────────────

  Widget _buildAdminTab() {
    if (!_isAdmin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              'Accès réservé aux administrateurs',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: Text(
              'Modifier le groupe',
              style: AppTextStyles.headline3,
            ),
          ),
          const SizedBox(height: 16),

          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: GlassTextField(
              controller: _nameCtrl,
              label: 'Nom du groupe',
            ),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: GlassTextField(
              controller: _descCtrl,
              label: 'Description',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Groupe public',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          _isPublicEdit
                              ? 'Visible par tous'
                              : 'Membres uniquement',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublicEdit,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isPublicEdit = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: GlassButton(
              label: 'Enregistrer les modifications',
              isLoading: _isSaving,
              onPressed: _saveGroupInfo,
            ),
          ),

          const SizedBox(height: 32),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Divider(color: AppColors.beigeDark.withAlpha(60)),
          ),
          const SizedBox(height: 16),

          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Text('Statistiques', style: AppTextStyles.headline3),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: Row(
              children: [
                _statCard(Icons.people_rounded, '${_members.length}',
                    'Membres actifs'),
                const SizedBox(width: 12),
                _statCard(
                    Icons.verified_rounded,
                    '${_members.where((m) => m.isModerator).length}',
                    'Modérateurs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.headline3
                    .copyWith(color: AppColors.primary)),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Group avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(40),
                          border: Border.all(
                              color: Colors.white.withAlpha(80), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            widget.groupName.isNotEmpty
                                ? widget.groupName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isPublic
                                ? Icons.public_rounded
                                : Icons.lock_rounded,
                            color: Colors.white.withAlpha(180),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isPublic ? 'Public' : 'Privé',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.people_rounded,
                              color: Colors.white.withAlpha(180), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingMembers
                                ? '… membres'
                                : '${_members.length} membre${_members.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withAlpha(150),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              tabs: [
                const Tab(
                  icon: Icon(Icons.people_outline_rounded, size: 18),
                  text: 'Membres',
                ),
                Tab(
                  icon: Icon(
                    _isAdmin
                        ? Icons.settings_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  text: 'Administration',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMembersTab(),
            _buildAdminTab(),
          ],
        ),
      ),
    );
  }
}
