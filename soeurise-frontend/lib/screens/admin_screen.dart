import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/models.dart';
import '../theme/glass_widgets.dart';
import '../services/admin_service.dart';
import '../services/event_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {};
  List<User> _users = [];
  List<Post> _posts = [];
  bool _isLoadingStats = true;
  bool _isLoadingUsers = true;
  bool _isLoadingPosts = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadStats();
    _loadUsers();
    _loadPosts();
    _loadEvents();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await AdminService.instance.fetchStats();
    if (mounted) setState(() { _stats = stats; _isLoadingStats = false; });
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() => _isLoadingUsers = true);
    final users = await AdminService.instance.fetchUsers(search: search);
    if (mounted) setState(() { _users = users; _isLoadingUsers = false; });
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    final posts = await AdminService.instance.fetchPosts();
    if (mounted) setState(() { _posts = posts; _isLoadingPosts = false; });
  }

  List<Event> _events = [];
  bool _isLoadingEvents = true;

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    final events = await EventService.instance.fetchEvents();
    if (mounted) setState(() { _events = events; _isLoadingEvents = false; });
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur ?'),
        content: Text('Voulez-vous supprimer ${user.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.instance.deleteUser(user.id);
      _loadUsers();
      _loadStats();
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    await AdminService.instance.updateUserStatus(user.id, !user.isActive);
    _loadUsers();
  }

  Future<void> _changeRole(User user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Modifier le rôle de ${user.username}'),
        children: ['user', 'admin', 'staff'].map((role) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, role),
            child: Row(
              children: [
                Icon(
                  role == user.role ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(role.toUpperCase(), style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (newRole != null && newRole != user.role) {
      await AdminService.instance.updateUserRole(user.id, newRole);
      _loadUsers();
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le post ?'),
        content: Text('Post de ${post.username} sera supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.instance.deletePost(post.id);
      _loadPosts();
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Administration', style: AppTextStyles.headline3),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.beige.withAlpha(120),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400),
              tabs: const [
                Tab(text: 'Utilisateurs'),
                Tab(text: 'Publications'),
                Tab(text: 'Événements'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats cards
          _buildStatsRow(),
          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildPostsTab(),
                _buildEventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final statItems = [
      _StatData(Icons.people_rounded, 'Utilisateurs', _stats['users'] ?? 0, const Color(0xFF64B5F6)),
      _StatData(Icons.article_rounded, 'Posts', _stats['posts'] ?? 0, AppColors.primary),
      _StatData(Icons.event_rounded, 'Événements', _stats['events'] ?? 0, AppColors.warningColor),
      _StatData(Icons.school_rounded, 'Masterclass', _stats['masterclasses'] ?? 0, const Color(0xFFBA68C8)),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: statItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final s = statItems[i];
          return Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.color.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(s.icon, color: s.color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.label,
                        style: AppTextStyles.caption.copyWith(color: s.color, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.count}',
                  style: AppTextStyles.headline3.copyWith(fontSize: 22, color: s.color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _loadUsers(search: val),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: Colors.white.withAlpha(180),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.beigeDark.withAlpha(60)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.beigeDark.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // User list
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _users.isEmpty
                  ? Center(child: Text('Aucun utilisateur trouvé', style: AppTextStyles.bodyMedium))
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _users.length,
                        itemBuilder: (ctx, i) => _buildUserTile(_users[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(User user) {
    Color roleColor;
    switch (user.role) {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'staff':
        roleColor = Colors.orange;
        break;
      default:
        roleColor = AppColors.successColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: Text(
                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username} · ${user.email}',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Status indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: user.isActive ? AppColors.successColor : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
              onSelected: (action) {
                switch (action) {
                  case 'role':
                    _changeRole(user);
                    break;
                  case 'status':
                    _toggleUserStatus(user);
                    break;
                  case 'delete':
                    _deleteUser(user);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'role', child: Text('Modifier le rôle')),
                PopupMenuItem(
                  value: 'status',
                  child: Text(user.isActive ? 'Désactiver' : 'Activer'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return _isLoadingPosts
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _posts.isEmpty
            ? Center(child: Text('Aucun post', style: AppTextStyles.bodyMedium))
            : RefreshIndicator(
                onRefresh: _loadPosts,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _posts.length,
                  itemBuilder: (ctx, i) => _buildPostTile(_posts[i]),
                ),
              );
  }

  Widget _buildPostTile(Post post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.username,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(post.timestamp),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${post.likes}', style: AppTextStyles.caption),
                      const SizedBox(width: 12),
                      Icon(Icons.chat_bubble_rounded, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('${post.comments}', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _deletePost(post),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassButton(
            label: 'Ajouter un événement',
            icon: Icons.add_rounded,
            onPressed: () => _showCreateEventDialog(),
          ),
        ),
        Expanded(
          child: _isLoadingEvents
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _events.isEmpty
                  ? Center(child: Text('Aucun événement', style: AppTextStyles.bodyMedium))
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: _events.length,
                        itemBuilder: (ctx, i) => _buildEventTile(_events[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEventTile(Event event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${event.dateTime.day}/${event.dateTime.month} · ${event.location}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateEventDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final imageUrlController = TextEditingController(text: 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?auto=format&fit=crop&q=80');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedType = 'physical';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouvel Événement', style: AppTextStyles.headline3),
                const SizedBox(height: 20),
                GlassTextField(controller: titleController, label: 'Titre de l\'événement'),
                const SizedBox(height: 16),
                GlassTextField(controller: locationController, label: 'Lieu ou Lien (Zoom)'),
                const SizedBox(height: 16),
                GlassTextField(controller: imageUrlController, label: 'URL de l\'image'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type', style: AppTextStyles.bodySmall),
                          DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'online', child: Text('En ligne')),
                              DropdownMenuItem(value: 'physical', child: Text('Présentiel')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: AppTextStyles.bodySmall),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setDialogState(() => selectedDate = date);
                            },
                            child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Créer l\'événement',
                  onPressed: () async {
                    if (titleController.text.isEmpty || locationController.text.isEmpty) return;
                    
                    final success = await EventService.instance.createEvent(
                      title: titleController.text,
                      location: locationController.text,
                      dateTime: selectedDate,
                      type: selectedType,
                      imageUrl: imageUrlController.text,
                    );

                    if (success && ctx.mounted) {
                      Navigator.pop(ctx);
                      _loadEvents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Événement créé !'), backgroundColor: AppColors.successColor),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  _StatData(this.icon, this.label, this.count, this.color);
}
