import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../models/models.dart';
import '../widgets/user_avatar.dart';
import '../services/community_service.dart';
import 'group_chat_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Community> communities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await CommunityService.instance.fetchGroups(
        search: search,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          communities = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des groupes';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoin(Community c) async {
    final success = await CommunityService.instance.joinGroup(c.id);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande traitée avec succès pour ${c.name}!'),
          backgroundColor: AppColors.successColor,
        ),
      );
      setState(() {}); // Trigger rebuild to show joined status
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de rejoindre ${c.name}. Vous avez peut-être déjà une demande en attente ou vous êtes banni.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _showCreateGroupSheet() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = true;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppBorderRadius.xxl),
                    topRight: Radius.circular(AppBorderRadius.xxl),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.beigeDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Creer un groupe', style: AppTextStyles.headline3),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: nameController,
                      label: 'Nom du groupe',
                    ),
                    const SizedBox(height: 12),
                    GlassTextField(
                      controller: descController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Groupe public',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Switch(
                          value: isPublic,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => isPublic = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      label: 'Creer',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        if (isSubmitting) return;
                        final name = nameController.text.trim();
                        final desc = descController.text.trim();
                        if (name.isEmpty || desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez remplir tous les champs')),
                          );
                          return;
                        }
                        setState(() => isSubmitting = true);
                        final created = await CommunityService.instance.createGroup(
                          name: name,
                          description: desc,
                          isPublic: isPublic,
                        );
                        setState(() => isSubmitting = false);

                        if (!context.mounted) return;
                        if (created != null) {
                          // Auto-join: creator is automatically an owner member
                          final s = Set<String>.from(CommunityService.instance.joined.value);
                          s.add(created.id);
                          CommunityService.instance.joined.value = s;
                          CommunityService.instance.saveJoinedState();

                          Navigator.pop(context);
                          await _loadCommunities();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Groupe cree avec succes'),
                              backgroundColor: AppColors.successColor,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de la creation du groupe'),
                              backgroundColor: AppColors.errorColor,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Navigator.of(context).canPop())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Communautes',
                              style: AppTextStyles.headline1,
                            ),
                          ),
                          GlassButton(
                            label: 'Creer',
                            width: 90,
                            onPressed: _showCreateGroupSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) => _loadCommunities(search: value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textLight, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _loadCommunities();
                          },
                        ),
                        hintText: 'Rechercher des communautés',
                        hintStyle: AppTextStyles.bodyMedium,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else if (communities.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Aucune communauté trouvée',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  ),
                ),
              )
            else ...[
              // Featured communities
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          'En vedette ✨',
                          style: AppTextStyles.headline3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: communities.length > 5 ? 5 : communities.length,
                        itemBuilder: (context, index) {
                          final c = communities[index];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 200 + (index * 50)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: _buildFeaturedCard(c),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // All communities header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Toutes les communautés',
                      style: AppTextStyles.headline3,
                    ),
                  ),
                ),
              ),

              // Vertial List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = communities[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 350 + (index * 50)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCommunityListItem(context, c),
                        ),
                      );
                    },
                    childCount: communities.length,
                  ),
                ),
              ),
            ],
            
            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Community c) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withAlpha(200),
            AppColors.primary.withAlpha(220),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background abstract shapes
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: AppTextStyles.headline4.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.members}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (CommunityService.instance.isMember(c.id)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupChatScreen(
                                communityId: c.id,
                                communityName: c.name,
                              ),
                        ),
                      );
                    } else {
                      _handleJoin(c);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      CommunityService.instance.isMember(c.id)
                          ? 'Ouvrir'
                          : 'Rejoindre',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildCommunityListItem(BuildContext context, Community c) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: CommunityService.instance.joined,
      builder: (context, joinedSet, child) {
        final isMember = joinedSet.contains(c.id);

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: c.imageUrl.isNotEmpty ? c.imageUrl : null,
                radius: 24,
                username: c.name.isNotEmpty ? c.name : '??',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: AppTextStyles.headline4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isMember
                  ? OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupChatScreen(
                                communityId: c.id,
                                communityName: c.name,
                              ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Ouvrir',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => _handleJoin(c),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withAlpha(100),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Rejoindre',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
