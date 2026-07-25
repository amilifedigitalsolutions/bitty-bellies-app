import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/recipe_provider.dart';
import '../../recipe/widgets/recipe_card.dart';
import 'saved_recipes_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) => user != null
          ? _AuthenticatedProfile(user: user)
          : _GuestProfile(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 72, color: AppColors.border),
              const SizedBox(height: 24),
              Text('Your profile', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Sign in to save recipes, share your creations, and connect with the community.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Sign in')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.push('/register'), child: const Text('Create account')),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedProfile extends ConsumerStatefulWidget {
  final UserProfile user;
  const _AuthenticatedProfile({required this.user});

  @override
  ConsumerState<_AuthenticatedProfile> createState() => _AuthenticatedProfileState();
}

class _AuthenticatedProfileState extends ConsumerState<_AuthenticatedProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final myRecipesAsync = ref.watch(myRecipesProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset('assets/logos/logo-long.png', height: 52, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null
                            ? Text(user.displayName[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: Theme.of(context).textTheme.headlineMedium),
                            if (user.country != null)
                              Text(user.country!, style: Theme.of(context).textTheme.bodySmall),
                            if (user.culturalBackground != null)
                              Text(user.culturalBackground!, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditProfile(context, user),
                      ),
                    ],
                  ),

                  if (user.bio != null) ...[
                    const SizedBox(height: 12),
                    Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('Recipes', '${user.uploadedRecipesCount}'),
                      _Stat('Saved', '${user.savedRecipesCount}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                tabs: const [Tab(text: 'My Recipes'), Tab(text: 'Saved')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            // My recipes
            myRecipesAsync.when(
              data: (recipes) => recipes.isEmpty
                  ? const EmptyView(message: 'No recipes yet', subMessage: 'Share your first baby-led weaning recipe!', icon: Icons.add_circle_outline)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: recipes.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RecipeCard(recipe: recipes[i], onTap: () => context.push('/recipe/${recipes[i].id}')),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
            ),

            // Saved recipes
            const SavedRecipesScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Settings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(currentUserProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _cultureCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _countryCtrl = TextEditingController(text: widget.user.country);
    _cultureCtrl = TextEditingController(text: widget.user.culturalBackground);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _cultureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          AppTextField(controller: _nameCtrl, label: 'Display name'),
          const SizedBox(height: 12),
          AppTextField(controller: _bioCtrl, label: 'Bio (optional)', maxLines: 2),
          const SizedBox(height: 12),
          AppTextField(controller: _countryCtrl, label: 'Country (optional)'),
          const SizedBox(height: 12),
          AppTextField(controller: _cultureCtrl, label: 'Cultural background / cooking style (optional)'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final updated = widget.user.copyWith(
                      displayName: _nameCtrl.text.trim(),
                      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
                      country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
                      culturalBackground: _cultureCtrl.text.trim().isEmpty ? null : _cultureCtrl.text.trim(),
                    );
                    await ref.read(authRepositoryProvider).updateProfile(updated);
                    await ref.read(currentUserProvider.notifier).refresh();
                    if (mounted) Navigator.pop(context);
                    setState(() => _saving = false);
                  },
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
