import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/recipe.dart';

/// Compact horizontal alternative to [RecipeCard] — thumbnail on the left,
/// content on the right — for contexts with many items in a row (Saved
/// panel, per-child folders) where the full vertical card takes up too
/// much scroll space.
class RecipeRowCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RecipeRowCard({super.key, required this.recipe, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 76, height: 76, child: _Thumbnail(url: recipe.coverImageUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        _MiniChip(recipe.ageStage),
                        _MiniChip(recipe.cuisine),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(recipe.totalTimeLabel, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.restaurant, size: 28, color: AppColors.border),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: Colors.white,
        child: Container(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.border),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}
