import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/illust.dart';
import '../services/api_service.dart';

class WaterfallGrid extends StatelessWidget {
  final List<Illust> illusts;
  final Function(Illust) onIllustTap;
  final bool isLoading;
  final ApiService _apiService = ApiService();

  static const double _baseColumnWidth = 200.0;
  static const double _maxColumnWidthIncrease = 1.5;
  static const double _cardContentHeight = 60.0;

  WaterfallGrid({
    super.key,
    required this.illusts,
    required this.onIllustTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        const horizontalPadding = 4.0 * 2;
        final availableWidth = parentWidth - horizontalPadding;

        final baseColumnCount = (availableWidth / _baseColumnWidth).floor();
        final columnCount = baseColumnCount.clamp(2, 4);

        final calculatedColumnWidth = availableWidth / columnCount;
        final columnWidth = calculatedColumnWidth.clamp(
          _baseColumnWidth,
          _baseColumnWidth * _maxColumnWidthIncrease,
        );

        final totalColumnsWidth = columnWidth * columnCount;
        final extraSpace = parentWidth - totalColumnsWidth;
        final adjustedPadding = (extraSpace / 2).clamp(4.0, double.infinity);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: adjustedPadding),
          child: MasonryGridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: columnCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: illusts.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= illusts.length) {
                if (isLoading) {
                  return Container(
                    height: 100,
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '加载中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final illust = illusts[index];
              final aspectRatio = illust.width / illust.height;
              final imageHeight = columnWidth / aspectRatio;

              return RepaintBoundary(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onIllustTap(illust),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: imageHeight,
                          width: columnWidth,
                          child: Hero(
                            tag: illust.id,
                            child: Material(
                              color: Colors.transparent,
                              child: CachedNetworkImage(
                                imageUrl: _apiService.getImageUrl(
                                  illust.image,
                                  illust.id,
                                  isThumb: true,
                                  page: illust.type == 2 ? -1 : 0,
                                ),
                                fit: BoxFit.cover,
                                memCacheHeight: imageHeight.ceil(),
                                memCacheWidth: columnWidth.ceil(),
                                fadeInDuration: const Duration(milliseconds: 150),
                                placeholderFadeInDuration: const Duration(milliseconds: 150),
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1F1F1F),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white70,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _cardContentHeight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    illust.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (illust.pageCount > 1) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.layers,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${illust.pageCount}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (illust.type == 2) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.animation,
                                            size: 14, color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
