import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';
import 'communities_screen.dart';
import 'masterclass_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'post_creation_screen.dart';
import 'admin_screen.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _iconControllers;
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  StreamSubscription? _notifSubscription;
  StreamSubscription? _msgSubscription;

  late final List<Widget> _screens;

  // 5 real screen tabs — no FAB confusion
  final List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Accueil'),
    _NavItem(Icons.group_rounded, Icons.group_outlined, 'Communautés'),
    _NavItem(Icons.school_rounded, Icons.school_outlined, 'Masterclass'),
    _NavItem(Icons.event_rounded, Icons.event_outlined, 'Événements'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();

    // 5 screens matching 5 nav items 1:1
    _screens = [
      HomeScreen(key: _homeScreenKey), // 0: Accueil
      const CommunitiesScreen(), // 1: Communautés
      const MasterclassScreen(), // 2: Masterclass
      const EventsScreen(), // 3: Événements
      const ProfileScreen(), // 4: Profil
    ];

    _iconControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _iconControllers[0].forward();

    // Init Socket and Notifications
    _initRealtime();
    NotificationService.instance.getUnreadCount();
  }

  void _initRealtime() {
    SocketService().init();
    
    _notifSubscription = SocketService().notificationStream.listen((notif) {
      if (mounted) {
        NotificationService.showNotificationSnackBar(
          context, 
          notif['text'] ?? 'Nouvelle notification'
        );
        // Update unread count
        NotificationService.instance.unreadCount.value++;
        
        // Also refresh profile if it was a follow request
        if (notif['type'] == 'follow') {
           ProfileService.instance.refreshProfile();
        }
      }
    });

    _msgSubscription = SocketService().messageStream.listen((msg) {
       if (mounted) {
         NotificationService.showNotificationSnackBar(
           context, 
           'Nouveau message de ${msg['sender']['username']}'
         );
       }
    });
  }

  @override
  void dispose() {
    for (var c in _iconControllers) {
      c.dispose();
    }
    _notifSubscription?.cancel();
    _msgSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;

    _iconControllers[_selectedIndex].reverse();
    _iconControllers[index].forward();
    setState(() => _selectedIndex = index);
  }

  Future<void> _openPostCreation() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PostCreationScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      _homeScreenKey.currentState?.refreshFeeds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      extendBody: true,
      // FAB for post creation — only visible on home screen
      floatingActionButton:
          _selectedIndex == 0
              ? Container(
                margin: const EdgeInsets.only(bottom: 0),
                child: FloatingActionButton(
                  heroTag: 'main_fab_post_creation',
                  onPressed: _openPostCreation,
                  backgroundColor: Colors.transparent,
                  elevation: 8,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation:
          _selectedIndex == 0 ? FloatingActionButtonLocation.centerFloat : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(color: Colors.white.withAlpha(120), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(15),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                return _buildNavItem(index);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    // Admin badge on profile icon (index 4)
    final isProfile = index == 4;
    final isAdmin =
        ProfileService.instance.profile.value.accountType == 'admin';

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        onLongPress:
            isProfile && isAdmin
                ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                }
                : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _iconControllers[index],
          builder: (context, _) {
            final scale = 1.0 + _iconControllers[index].value * 0.1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary.withAlpha(25)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textLight,
                          size: 22,
                        ),
                        if (isProfile) ...[
                          if (isAdmin)
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ValueListenableBuilder<int>(
                            valueListenable: ProfileService.instance.pendingFollowRequestsCount,
                            builder: (context, count, _) {
                              if (count <= 0) return const SizedBox.shrink();
                              return Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(40),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSelected ? 10 : 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textLight,
                  ),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  _NavItem(this.activeIcon, this.icon, this.label);
}
