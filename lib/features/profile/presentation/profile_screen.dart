import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/data/auth_controller.dart';
import '../../../features/auth/presentation/auth_screen.dart';
import '../../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../../features/bookmarks/presentation/bookmarks_controller.dart';
import '../../../shared/models/user_profile_model.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<UserProfileModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UserProfileModel> _load() {
    return ref
        .read(backendServiceProvider)
        .fetchProfileDetails()
        .catchError((error) async {
      if (error is ApiException && error.statusCode == 401) {
        await ref.read(authControllerProvider.notifier).clearSession();
      }
      throw error;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: FutureBuilder<UserProfileModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            final error = snapshot.error;
            final isUnauthorized =
                error is ApiException && error.statusCode == 401;
            final message = error is ApiException
                ? error.message
                : 'تحقق من الاتصال ثم حاول مرة أخرى.';

            return AppStateView(
              icon: Icons.person_off_outlined,
              title: isUnauthorized
                  ? 'انتهت جلسة تسجيل الدخول'
                  : 'تعذر تحميل الملف الشخصي',
              message: message,
              actionLabel: isUnauthorized ? 'تسجيل الدخول' : 'إعادة المحاولة',
              onAction: () {
                if (isUnauthorized) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                } else {
                  _refresh();
                }
              },
            );
          }

          final profile = snapshot.data!;
          final savedBookmarksCount =
              ref.watch(bookmarksControllerProvider).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 12),
                _CountersCard(
                  profile: profile,
                  savedArticlesCount: savedBookmarksCount,
                  onSavedTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BookmarksScreen()),
                    );
                  },
                  onLikesTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyLikesScreen()),
                    );
                  },
                  onCommentsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MyCommentsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'تعديل الملف الشخصي',
                  subtitle: 'تعديل الاسم والصورة الشخصية (اختياري).',
                  icon: Icons.edit_outlined,
                  onTap: () async {
                    final changed =
                        await _showEditProfileDialog(context, profile);
                    if (changed == true) {
                      await ref
                          .read(authControllerProvider.notifier)
                          .refreshProfile();
                      await _refresh();
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ActionCard(
                  title: 'تغيير كلمة المرور',
                  subtitle: 'حافظ على أمان حسابك بكلمة مرور قوية.',
                  icon: Icons.lock_outline,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const SizedBox(height: 8),
                _ActionCard(
                  title: 'حذف الحساب',
                  subtitle: 'سيتم حذف الجلسات وإيقاف الحساب نهائياً.',
                  icon: Icons.delete_outline,
                  danger: true,
                  onTap: () => _showDeleteAccountDialog(context, profile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showEditProfileDialog(
      BuildContext context, UserProfileModel profile) {
    final nameController = TextEditingController(text: profile.name);
    final picker = ImagePicker();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        String? error;
        String? selectedImagePath;
        bool removeAvatar = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final hasCurrentAvatar = (profile.avatarUrl ?? '').isNotEmpty &&
                !removeAvatar &&
                selectedImagePath == null;

            return AlertDialog(
              title: const Text('تعديل الملف الشخصي'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: hasCurrentAvatar
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: hasCurrentAvatar
                            ? null
                            : const Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedImagePath != null
                              ? 'تم اختيار صورة جديدة.'
                              : removeAvatar
                                  ? 'سيتم حذف الصورة الحالية.'
                                  : hasCurrentAvatar
                                      ? 'الصورة الحالية.'
                                      : 'لا توجد صورة حالياً.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                  maxWidth: 1400,
                                );
                                if (file == null) return;
                                setStateDialog(() {
                                  selectedImagePath = file.path;
                                  removeAvatar = false;
                                });
                              },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('اختيار صورة'),
                      ),
                      if ((profile.avatarUrl ?? '').isNotEmpty ||
                          selectedImagePath != null)
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () {
                                  setStateDialog(() {
                                    selectedImagePath = null;
                                    removeAvatar = true;
                                  });
                                },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('إزالة الصورة'),
                        ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() {
                            isSaving = true;
                            error = null;
                          });

                          try {
                            await ref
                                .read(backendServiceProvider)
                                .updateProfile(
                                  name: nameController.text.trim(),
                                  avatarFilePath: selectedImagePath,
                                  removeAvatar: removeAvatar,
                                );
                            if (mounted) {
                              Navigator.pop(context, true);
                            }
                          } on ApiException catch (e) {
                            setStateDialog(() {
                              error = e.message;
                              isSaving = false;
                            });
                          } catch (_) {
                            setStateDialog(() {
                              error = 'تعذر تحديث الملف الشخصي.';
                              isSaving = false;
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isSaving = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('تغيير كلمة المرور'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'كلمة المرور الحالية'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() {
                            isSaving = true;
                            error = null;
                          });

                          try {
                            await ref
                                .read(backendServiceProvider)
                                .changePassword(
                                  currentPassword: currentController.text,
                                  newPassword: newController.text,
                                  newPasswordConfirmation:
                                      confirmController.text,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('تم تغيير كلمة المرور بنجاح.')),
                              );
                            }
                          } on ApiException catch (e) {
                            setStateDialog(() {
                              error = e.message;
                              isSaving = false;
                            });
                          } catch (_) {
                            setStateDialog(() {
                              error = 'تعذر تغيير كلمة المرور.';
                              isSaving = false;
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تغيير'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog(
      BuildContext context, UserProfileModel profile) async {
    final passwordController = TextEditingController();
    final isGoogleAccount = profile.provider == 'google';

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool isDeleting = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('تأكيد حذف الحساب'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isGoogleAccount
                        ? 'هذا الإجراء نهائي ولا يمكن التراجع عنه. سيتم حذف حساب Google مباشرة بعد التأكيد.'
                        : 'هذا الإجراء نهائي ولا يمكن التراجع عنه. أدخل كلمة المرور للتأكيد.',
                  ),
                  if (!isGoogleAccount) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'كلمة المرور'),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setStateDialog(() {
                            isDeleting = true;
                            error = null;
                          });

                          try {
                            await ref
                                .read(backendServiceProvider)
                                .deleteAccount(
                                  password: isGoogleAccount
                                      ? null
                                      : passwordController.text,
                                );
                            await ref
                                .read(authControllerProvider.notifier)
                                .clearSession();

                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pop(this.context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذ الحساب بنجاح.'),
                                ),
                              );
                            }
                          } on ApiException catch (e) {
                            setStateDialog(() {
                              error = e.message;
                              isDeleting = false;
                            });
                          } catch (_) {
                            setStateDialog(() {
                              error = 'تعذر حذف الحساب.';
                              isDeleting = false;
                            });
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حذف الحساب'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final created = profile.createdAt == null
        ? '-'
        : DateFormat('yyyy/MM/dd').format(profile.createdAt!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.yellow.withOpacity(0.18),
              backgroundImage:
                  profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
              child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                  ? const Icon(Icons.person_outline, size: 34)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(label: Text('الدور: ${_roleToArabic(profile.role)}')),
                Chip(label: Text('تاريخ الإنشاء: $created')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleToArabic(String role) {
    switch (role) {
      case 'super_admin':
        return 'مدير عام';
      case 'admin':
        return 'مدير';
      case 'editor':
        return 'محرر';
      case 'moderator':
        return 'مشرف';
      case 'analyst':
        return 'محلل';
      default:
        return 'مستخدم';
    }
  }
}

class _CountersCard extends StatelessWidget {
  const _CountersCard({
    required this.profile,
    required this.savedArticlesCount,
    required this.onSavedTap,
    required this.onLikesTap,
    required this.onCommentsTap,
  });

  final UserProfileModel profile;
  final int savedArticlesCount;
  final VoidCallback onSavedTap;
  final VoidCallback onLikesTap;
  final VoidCallback onCommentsTap;

  @override
  Widget build(BuildContext context) {
    Widget tile({
      required String label,
      required int value,
      required VoidCallback onTap,
      required IconData icon,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: AppColors.gold),
                const SizedBox(height: 4),
                Text('$value', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            tile(
              label: 'المحفوظات',
              value: savedArticlesCount,
              onTap: onSavedTap,
              icon: Icons.bookmark_outline,
            ),
            const SizedBox(width: 8),
            tile(
              label: 'الإعجابات',
              value: profile.likesCount,
              onTap: onLikesTap,
              icon: Icons.favorite_border,
            ),
            const SizedBox(width: 8),
            tile(
              label: 'التعليقات',
              value: profile.commentsCount,
              onTap: onCommentsTap,
              icon: Icons.mode_comment_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class MyCommentsScreen extends ConsumerWidget {
  const MyCommentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعليقاتي')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(backendServiceProvider).fetchMyComments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'تعذر تحميل التعليقات.';
            return AppStateView(
              icon: Icons.error_outline,
              title: 'تعذر تحميل التعليقات',
              message: message,
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.mode_comment_outlined,
              title: 'لا توجد تعليقات',
              message: 'لم تقم بإضافة تعليقات بعد.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final articleId =
                  int.tryParse((item['article_id'] ?? '').toString()) ?? 0;
              final status = (item['status'] ?? '').toString();
              final statusLabel = status == 'approved'
                  ? 'معتمد'
                  : status == 'rejected'
                      ? 'مرفوض'
                      : 'قيد المراجعة';

              return Card(
                child: ListTile(
                  title: Text((item['content'] ?? '').toString(),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('المقال #$articleId - الحالة: $statusLabel'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: articleId > 0
                      ? () => context.push('/article/$articleId')
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MyLikesScreen extends ConsumerWidget {
  const MyLikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعجاباتي')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(backendServiceProvider).fetchMyLikes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'تعذر تحميل الإعجابات.';
            return AppStateView(
              icon: Icons.error_outline,
              title: 'تعذر تحميل الإعجابات',
              message: message,
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.favorite_border,
              title: 'لا توجد إعجابات',
              message: 'لم تقم بالإعجاب بأي مقال بعد.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final articleId =
                  int.tryParse((item['article_id'] ?? '').toString()) ?? 0;

              return Card(
                child: ListTile(
                  title: Text('مقال رقم #$articleId'),
                  subtitle: const Text('اضغط لفتح المقال'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: articleId > 0
                      ? () => context.push('/article/$articleId')
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Theme.of(context).colorScheme.primary;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
