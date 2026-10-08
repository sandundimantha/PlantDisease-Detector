import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/announcements_provider.dart';

import 'dart:ui';

class _ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const _ShimmerSkeleton({required this.width, required this.height, this.borderRadius = 8});

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.1, 0.5, 0.9],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
        );
      }
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Notifications', si: 'දැනුම්දීම්', ta: 'அறிவிப்புகள்')),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr(en: 'All marked as read', si: 'සියල්ල කියවූ ලෙස සලකුණු කළා', ta: 'அனைத்தும் படித்ததாகக் குறிக்கப்பட்டது'))),
              );
            },
            tooltip: 'Mark all as read',
          ),
          const LanguageSelectorButton(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: announcementsAsync.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const _ShimmerSkeleton(width: 50, height: 50, borderRadius: 25),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _ShimmerSkeleton(width: 150, height: 16),
                        SizedBox(height: 8),
                        _ShimmerSkeleton(width: double.infinity, height: 12),
                        SizedBox(height: 4),
                        _ShimmerSkeleton(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (err, stack) => Center(child: Text('Error: $err')),
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr(en: 'All caught up!', si: 'සියල්ල කියවා ඇත!', ta: 'அனைத்தும் படிக்கப்பட்டது!'),
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(en: 'You have no new notifications.', si: 'නව දැනුම්දීම් නැත.', ta: 'புதிய அறிவிப்புகள் இல்லை.'),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final a = announcements[index];
              return _buildNotificationCard(
                type: 'alert',
                title: a['title'] ?? 'Announcement',
                message: a['content'] ?? '',
                time: _timeAgo(DateTime.parse(a['created_at'])),
                isUnread: true,
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'alert':
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        break;
      case 'reminder':
        icon = Icons.medication_liquid_rounded;
        iconColor = AppColors.secondary;
        bgColor = AppColors.secondary.withValues(alpha: 0.1);
        break;
      case 'success':
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      default:
        icon = Icons.info_outline_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          if (!isUnread)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isUnread ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }
}

