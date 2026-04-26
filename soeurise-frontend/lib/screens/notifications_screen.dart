import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotifData(
        Icons.favorite_rounded,
        'Aisha a aimé votre publication',
        'Il y a 2h',
        AppColors.primary,
      ),
      _NotifData(
        Icons.comment_rounded,
        'Zainab a commenté votre post',
        'Il y a 3h',
        const Color(0xFF64B5F6),
      ),
      _NotifData(
        Icons.event_rounded,
        'Nouvel événement: Femmes Leaders',
        'Il y a 5h',
        AppColors.warningColor,
      ),
      _NotifData(
        Icons.group_add_rounded,
        'Maryam a rejoint votre communauté',
        'Il y a 1j',
        AppColors.successColor,
      ),
      _NotifData(
        Icons.school_rounded,
        'Nouvelle masterclass disponible',
        'Il y a 2j',
        const Color(0xFFBA68C8),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(180),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Notifications', style: AppTextStyles.headline2),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Tout lire',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final n = notifications[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: index * 80),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.color.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(n.icon, color: n.color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.text,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n.time, style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index < 2
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  _NotifData(this.icon, this.text, this.time, this.color);
}
