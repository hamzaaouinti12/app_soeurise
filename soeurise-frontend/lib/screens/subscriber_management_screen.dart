import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';
import 'follow_requests_screen.dart';

class SubscriberManagementScreen extends StatefulWidget {
  const SubscriberManagementScreen({super.key});

  @override
  State<SubscriberManagementScreen> createState() =>
      _SubscriberManagementScreenState();
}

class _SubscriberManagementScreenState
    extends State<SubscriberManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Gestion des abonnes',
          style: AppTextStyles.headline3.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Abonnes'),
            Tab(text: 'Abonnements'),
            Tab(text: 'Demandes'),
          ],
        ),
      ),
      body: ValueListenableBuilder<Profile>(
        valueListenable: ProfileService.instance.profile,
        builder: (context, profile, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              const FollowersListScreen(),
              const FollowingListScreen(),
              profile.isPrivateAccount
                  ? const FollowRequestsScreen()
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Les demandes d\'abonnement sont disponibles en mode prive.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
