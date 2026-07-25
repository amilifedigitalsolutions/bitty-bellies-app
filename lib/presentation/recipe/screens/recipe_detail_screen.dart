import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_comment.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/recipe_provider.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    return recipeAsync.when(
      data: (recipe) => _RecipeDetail(recipe: recipe),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(recipeDetailProvider(recipeId)))),
    );
  }
}

class _RecipeDetail extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _RecipeDetail({required this.recipe});

  @override
  ConsumerState<_RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends ConsumerState<_RecipeDetail> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _savingInFlight = false;

  Future<void> _save() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) { context.push('/login'); return; }
    if (_savingInFlight) return;
    setState(() => _savingInFlight = true);

    final repo = ref.read(recipeRepositoryProvider);
    final isSavedResult = await repo.isRecipeSaved(widget.recipe.id);
    await isSavedResult.when(
      success: (saved) async {
        final result = saved
            ? await repo.unsaveRecipe(widget.recipe.id)
            : await repo.saveRecipe(widget.recipe.id);
        result.when(
          success: (_) {
            ref.invalidate(isRecipeSavedProvider(widget.recipe.id));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(saved ? 'Removed from saved recipes' : 'Saved to your recipes')),
              );
            }
          },
          failure: (e) => _showSaveError(e.message),
        );
      },
      failure: (e) async => _showSaveError(e.message),
    );

    if (mounted) setState(() => _savingInFlight = false);
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update saved status: $message')),
    );
  }

  Future<void> _share() async {
    await Share.share('A parent-tested recipe from Bitty Bellies: ${widget.recipe.title}');
  }

  Future<void> _report() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) { context.push('/login'); return; }
    await _showReportDialog(context, ref, widget.recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isSavedAsync = ref.watch(isRecipeSavedProvider(recipe.id));
    final isSaved = isSavedAsync.valueOrNull ?? false;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.coverImageUrl != null
                  ? CachedNetworkImage(imageUrl: recipe.coverImageUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.restaurant, size: 72, color: AppColors.border)),
            ),
            actions: [
              IconButton(
                icon: _savingInFlight
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: _savingInFlight ? null : _save,
                color: Colors.white,
              ),
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _share),
              IconButton(icon: const Icon(Icons.flag_outlined, color: Colors.white), onPressed: _report),
            ],
          ),
          SliverToBoxAdapter(
            // Recipe header info
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Tag(recipe.ageStage, color: AppColors.secondaryLight),
                      _Tag(recipe.texture, color: AppColors.surfaceVariant),
                      _Tag(recipe.cuisine, color: AppColors.surfaceVariant),
                      ...recipe.mealCategories.map((c) => _Tag(c, color: AppColors.surfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(recipe.title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),

                  // Creator row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: recipe.creatorAvatarUrl != null
                            ? CachedNetworkImageProvider(recipe.creatorAvatarUrl!)
                            : null,
                        child: recipe.creatorAvatarUrl == null
                            ? Text(recipe.creatorName[0], style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('by ${recipe.creatorName}', style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(recipe.totalTimeLabel, style: Theme.of(context).textTheme.bodySmall),
                      if (recipe.servings != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${recipe.servings}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(recipe.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),

                  // Safety / allergen banners
                  if (recipe.allergens.isNotEmpty)
                    _SafetyBanner(
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.allergenTag,
                      label: 'Allergens: ${recipe.allergens.join(', ')}',
                    ),
                  if (recipe.chokingHazardNotes != null) ...[
                    const SizedBox(height: 6),
                    _SafetyBanner(
                      icon: Icons.report_problem_outlined,
                      color: AppColors.chokingTag.withValues(alpha: 0.2),
                      label: 'Choking hazard: ${recipe.chokingHazardNotes}',
                      iconColor: AppColors.chokingTag,
                    ),
                  ],
                  if (recipe.safetyNotes != null) ...[
                    const SizedBox(height: 6),
                    _SafetyBanner(
                      icon: Icons.info_outline,
                      color: AppColors.secondaryLight.withValues(alpha: 0.3),
                      label: recipe.safetyNotes!,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Disclaimer
                  Text(
                    AppConstants.safetyDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),

                  // Diet tags
                  if (recipe.dietTypes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: recipe.dietTypes.map((d) => _Tag(d, color: AppColors.secondaryLight.withValues(alpha: 0.4))).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tab bar: Recipe | Comments | Questions — pinned so it stays
          // visible while the tab content below scrolls.
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Recipe'),
                  Tab(text: 'Comments'),
                  Tab(text: 'Questions'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _RecipeTab(recipe: recipe),
            _CommentsTab(recipeId: recipe.id),
            _QuestionsTab(recipeId: recipe.id, creatorId: recipe.creatorId),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}

// ── Tab: Ingredients + Steps ─────────────────────────────────────────────────

class _RecipeTab extends StatelessWidget {
  final Recipe recipe;
  const _RecipeTab({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timing row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBox('Prep', '${recipe.prepTimeMinutes}m'),
            _StatBox('Cook', '${recipe.cookTimeMinutes}m'),
            _StatBox('Total', recipe.totalTimeLabel),
            if (recipe.servings != null) _StatBox('Serves', '${recipe.servings}'),
          ],
        ),
        const SizedBox(height: 24),

        Text('Ingredients', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...recipe.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 6), child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${ing.quantity}${ing.unit != null ? ' ${ing.unit}' : ''} ${ing.name}${ing.notes != null ? ' (${ing.notes})' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),

        Text('Instructions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...recipe.steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text('${step.stepNumber}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.instruction, style: Theme.of(context).textTheme.bodyMedium),
                        if (step.tip != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('💡 ${step.tip}', style: Theme.of(context).textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

        if (recipe.storageReheatingNotes != null) ...[
          const SizedBox(height: 16),
          Text('Storage & reheating', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(recipe.storageReheatingNotes!, style: Theme.of(context).textTheme.bodyMedium),
        ],

        if (recipe.creatorNotes != null) ...[
          const SizedBox(height: 16),
          Text('Creator notes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(recipe.creatorNotes!, style: Theme.of(context).textTheme.bodyMedium),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Tab: Comments ─────────────────────────────────────────────────────────────

class _CommentsTab extends ConsumerStatefulWidget {
  final String recipeId;
  const _CommentsTab({required this.recipeId});

  @override
  ConsumerState<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends ConsumerState<_CommentsTab> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) { context.push('/login'); return; }
    setState(() => _sending = true);
    final repo = ref.read(recipeRepositoryProvider);
    final result = await repo.addComment(widget.recipeId, text);
    result.when(
      success: (_) {
        _ctrl.clear();
        ref.invalidate(recipeCommentsProvider(widget.recipeId));
      },
      failure: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not post comment: ${e.message}')),
          );
        }
      },
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(recipeCommentsProvider(widget.recipeId));
    return Column(
      children: [
        Expanded(
          child: commentsAsync.when(
            data: (comments) => comments.isEmpty
                ? const EmptyView(message: 'No comments yet', subMessage: 'Be the first to share your thoughts.')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (_, i) => _CommentTile(comment: comments[i], recipeId: widget.recipeId),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(recipeCommentsProvider(widget.recipeId))),
          ),
        ),
        _CommentInput(controller: _ctrl, sending: _sending, onSend: _submit),
      ],
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final RecipeComment comment;
  final String recipeId;
  const _CommentTile({required this.comment, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isOwn = user?.id == comment.authorId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(comment.authorName[0]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName, style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (isOwn)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await ref.read(recipeRepositoryProvider).deleteComment(comment.id);
                          ref.invalidate(recipeCommentsProvider(recipeId));
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _CommentInput({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: AppColors.primary),
            onPressed: sending ? null : onSend,
          ),
        ],
      ),
    );
  }
}

// ── Tab: Questions ────────────────────────────────────────────────────────────

class _QuestionsTab extends ConsumerStatefulWidget {
  final String recipeId;
  final String creatorId;
  const _QuestionsTab({required this.recipeId, required this.creatorId});

  @override
  ConsumerState<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends ConsumerState<_QuestionsTab> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) { context.push('/login'); return; }
    setState(() => _sending = true);
    final repo = ref.read(recipeRepositoryProvider);
    final result = await repo.addQuestion(widget.recipeId, text);
    result.when(
      success: (_) {
        _ctrl.clear();
        ref.invalidate(recipeQuestionsProvider(widget.recipeId));
      },
      failure: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not post question: ${e.message}')),
          );
        }
      },
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(recipeQuestionsProvider(widget.recipeId));
    return Column(
      children: [
        Expanded(
          child: questionsAsync.when(
            data: (questions) => questions.isEmpty
                ? const EmptyView(message: 'No questions yet', subMessage: 'Ask the creator anything about this recipe.')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (_, i) => _QuestionTile(question: questions[i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(message: e.toString()),
          ),
        ),
        _CommentInput(
          controller: _ctrl,
          sending: _sending,
          onSend: _submit,
        ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final RecipeQuestion question;
  const _QuestionTile({required this.question});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text(question.authorName[0])),
              const SizedBox(width: 8),
              Text(question.authorName, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(_timeAgo(question.createdAt), style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(question.question, style: Theme.of(context).textTheme.bodyMedium),
          if (question.isAnsweredByCreator && question.creatorAnswer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondaryLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Creator replied:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(question.creatorAnswer!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

class _SafetyBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? iconColor;
  const _SafetyBanner({required this.icon, required this.color, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

Future<void> _showReportDialog(BuildContext context, WidgetRef ref, String recipeId) async {
  String? selected;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Report this recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.reportReasons
              .map((r) => RadioListTile<String>(
                    title: Text(r),
                    value: r,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: selected == null
                ? null
                : () async {
                    await ref.read(recipeRepositoryProvider).reportRecipe(recipeId, selected!);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            child: const Text('Report'),
          ),
        ],
      ),
    ),
  );
}
