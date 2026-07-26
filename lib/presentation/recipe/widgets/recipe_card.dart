import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverImage(url: recipe.coverImageUrl),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age stage + cuisine chips
                  Row(
                    children: [
                      _MiniChip(recipe.ageStage, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      _MiniChip(recipe.cuisine, color: AppColors.surfaceVariant),
                      if (recipe.pendingLabel != null) ...[
                        const SizedBox(width: 6),
                        _MiniChip(recipe.pendingLabel!, color: AppColors.primaryLight),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    recipe.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    recipe.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(recipe.totalTimeLabel, style: theme.textTheme.labelSmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.bookmark_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('${recipe.savedCount}', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 12),
                      if (recipe.averageRating != null) ...[
                        const Icon(Icons.star_outline, size: 14, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(recipe.averageRating!.toStringAsFixed(1), style: theme.textTheme.labelSmall),
                      ],
                      const Spacer(),
                      Text(
                        'by ${recipe.creatorName}',
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Allergen warning banner
                  if (recipe.allergens.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.allergenTag,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_outlined, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Contains: ${recipe.allergens.take(2).join(', ')}${recipe.allergens.length > 2 ? '...' : ''}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Choking hazard tag
                  if (recipe.chokingHazardNotes != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.chokingTag.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 12, color: AppColors.chokingTag),
                          SizedBox(width: 4),
                          Text('Choking hazard note', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.chokingTag)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? url;
  const _CoverImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        height: 180,
        color: AppColors.surfaceVariant,
        child: const Center(child: Icon(Icons.restaurant, size: 48, color: AppColors.border)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: Colors.white,
        child: Container(height: 180, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 180,
        color: AppColors.surfaceVariant,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.border)),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// Shimmer placeholder for loading state
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 180, color: Colors.white),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerLine(width: 80, height: 14),
                  SizedBox(height: 8),
                  _ShimmerLine(width: double.infinity, height: 18),
                  SizedBox(height: 6),
                  _ShimmerLine(width: 200, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      );
}
