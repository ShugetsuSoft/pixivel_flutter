import 'dart:typed_data';

import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pixivel_flutter/widgets/waterfall_grid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:universal_platform/universal_platform.dart';
import 'package:gal/gal.dart';

import '../models/illust.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_loading.dart';
import 'full_screen_image_viewer.dart';
import '../models/api_response.dart';
import 'illustrator_profile_page.dart';
import 'search_page.dart';

class IllustDetailPage extends StatefulWidget {
  final Illust? illust;
  final int? illustId;
  final UserIllustsResponse? userIllusts;
  final bool? isFromIllustDetail;

  const IllustDetailPage({
    super.key,
    this.illust,
    this.illustId,
    this.userIllusts,
    this.isFromIllustDetail,
  }) : assert(illust != null || illustId != null);

  @override
  State<IllustDetailPage> createState() => _IllustDetailPageState();
}

class _IllustDetailPageState extends State<IllustDetailPage> {
  final ApiService _apiService = ApiService();
  Illust? _illust;
  int _currentPage = 0;
  bool _isLoading = false;
  final CarouselController _carouselController = CarouselController();
  UserIllustsResponse? _userIllusts;
  bool _isLoadingUserIllusts = false;
  final ScrollController _horizontalScrollController = ScrollController();
  PageStorageBucket? _bucket;

  // 推荐插画相关变量
  final List<Illust> _recommendIllusts = [];
  bool _isLoadingRecommends = false;
  bool _hasMoreRecommends = true;
  int _currentRecommendPage = 0;

  DateTime _parseDate(String dateStr) {
    // Convert from 'yyyyMMdd' to 'yyyy-MM-dd' format
    final formattedDate =
        dateStr.replaceAll(RegExp(r'(\d{4})(\d{2})(\d{2})'), '\$1-\$2-\$3');
    return DateTime.parse(formattedDate);
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _illust!.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (_illust!.altTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _illust!.altTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54,
                  ),
            ),
          ),
        const Divider(
          color: Colors.white24,
          thickness: 1,
          height: 20,
        ),
        if (_illust!.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Html(
            data: _illust!.description,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(14),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
              "a": Style(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue
                    : Colors.blue,
                textDecoration: TextDecoration.none,
              ),
            },
            onLinkTap: (url, _, __) async {
              if (url != null) {
                Uri uri;
                if (url.startsWith('/jump.php?')) {
                  final encodedUrl = url.substring('/jump.php?'.length);
                  final decodedUrl = Uri.decodeComponent(encodedUrl);
                  uri = Uri.parse(decodedUrl);
                } else {
                  uri = Uri.parse(url);
                }

                if (await canLaunchUrl(uri)) {
                  final bool? proceed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          '一个外部链接',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '你正在打开一个外部链接:',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              uri.toString(),
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.blue
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '真的要继续吗？我可无法继续保护主人的安全了',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Open'),
                          ),
                        ],
                      );
                    },
                  );

                  if (proceed == true) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _illust!.tags.map((tag) {
            return IntrinsicWidth(
              child: ActionChip(
                label: SizedBox(
                  height: 32,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag.name,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        if (tag.translation.isNotEmpty)
                          Text(
                            tag.translation,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white54
                                  : Colors.black54,
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        initialSearchText: tag.name,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildStatItem(
                Icons.remove_red_eye, _illust!.statistic.views.toString()),
            const SizedBox(width: 8),
            _buildStatItem(Icons.favorite, _illust!.statistic.likes.toString()),
            const SizedBox(width: 8),
            _buildStatItem(
                Icons.bookmark, _illust!.statistic.bookmarks.toString()),
            const SizedBox(width: 8),
            _buildStatItem(
                Icons.comment, _illust!.statistic.comments.toString()),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.download),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              onPressed: _downloadImage,
              tooltip: '下载当前图片',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          () {
            final date = _parseDate(_illust!.createDate);
            return '发布于 ${date.year}年${date.month}月${date.day}日';
          }(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black54,
              ),
        ),
        const SizedBox(height: 16),
        // Illustrator Profile
        if (_userIllusts?.user != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(
                      name: 'illustrator_profile_${_userIllusts!.user.id}',
                    ),
                    builder: (context) => IllustratorProfilePage(
                      userId: _userIllusts!.user.id,
                      user: _userIllusts!.user,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: "user_avatar_${_userIllusts!.user.id}",
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CachedNetworkImage(
                          imageUrl: _apiService.getUserImageUrl(
                            _userIllusts!.user.image.url,
                            _userIllusts!.user.id,
                          ),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1F1F1F),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userIllusts!.user.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_userIllusts!.user.bio.isNotEmpty)
                            Text(
                              _userIllusts!.user.bio,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_isLoadingUserIllusts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                ShimmerLoading(width: 50, height: 50, borderRadius: 25),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: 120, height: 20, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerLoading(width: 200, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // User Illustrations
        if (_userIllusts?.illusts != null && _userIllusts!.illusts.isNotEmpty)
          SizedBox(
            height: 120,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  true, // Prevent scroll from propagating
              child: MouseRegion(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final delta = pointerSignal.scrollDelta.dy;
                      _horizontalScrollController.position.moveTo(
                        _horizontalScrollController.position.pixels + delta,
                        curve: Curves.linear,
                      );
                    }
                  },
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: false,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _userIllusts!.illusts.length,
                      itemBuilder: (context, index) => _buildUserIllustItem(
                        _userIllusts!.illusts[index],
                        index,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (_isLoadingUserIllusts)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: 8,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: const ShimmerLoading(
                    width: 120,
                    height: 120,
                    borderRadius: 8,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUserIllustItem(Illust illust, int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: 8,
        left: index == 0 ? 0 : 0,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: RouteSettings(name: 'illust_detail_${illust.id}'),
              builder: (context) => IllustDetailPage(
                illust: illust,
                userIllusts: _userIllusts,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: CachedNetworkImage(
                          imageUrl: _apiService.getImageUrl(
                            illust.image,
                            illust.id,
                            isThumb: true,
                          ),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1F1F1F),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            illust.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustImage({bool isWideScreen = false}) {
    return _illust!.pageCount > 1
        ? Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings:
                          RouteSettings(name: 'full_screen_${_illust!.id}'),
                      builder: (context) => FullScreenImageViewer(
                        illust: _illust!,
                        initialIndex: _currentPage,
                      ),
                    ),
                  );
                },
                child: FlutterCarousel.builder(
                  itemCount: _illust!.pageCount,
                  itemBuilder: (context, index, realIndex) {
                    return CachedNetworkImage(
                      imageUrl: _apiService.getImageUrl(
                        _illust!.image,
                        _illust!.id,
                        page: index,
                      ),
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1F1F1F),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    );
                  },
                  options: CarouselOptions(
                    viewportFraction: 1.0,
                    height: double.infinity,
                    showIndicator: false,
                    initialPage: _currentPage,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentPage = index;
                        _savePage(index);
                      });
                    },
                    controller: _carouselController,
                    enableInfiniteScroll: false,
                  ),
                ),
              ),
              if (_illust!.pageCount > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${_illust!.pageCount}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentPage > 0)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      _carouselController.previousPage();
                                    },
                                    child: Text(
                                      'PREV',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 40),
                              const Spacer(),
                              if (_currentPage < _illust!.pageCount - 1)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      _carouselController.nextPage();
                                    },
                                    child: Text(
                                      'NEXT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          )
        : GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: RouteSettings(name: 'full_screen_${_illust!.id}'),
                  builder: (context) => FullScreenImageViewer(
                    illust: _illust!,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: _apiService.getImageUrl(
                _illust!.image,
                _illust!.id,
              ),
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                color: const Color(0xFF1F1F1F),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
  }

  Future<void> _loadUserIllusts() async {
    if (_illust == null || _isLoadingUserIllusts) return;

    setState(() {
      _isLoadingUserIllusts = true;
    });

    try {
      final response = await _apiService.getUserIllusts(_illust!.user);
      if (!mounted) return;
      setState(() {
        _userIllusts = response.data;
        _isLoadingUserIllusts = false;
      });

      // Find and scroll to current illust in the next tick
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentIllust();
      });
    } catch (e) {
      debugPrint('Error loading user illusts: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingUserIllusts = false;
      });
    }
  }

  void _scrollToCurrentIllust() {
    if (_userIllusts == null || _illust == null) return;

    final currentIndex =
        _userIllusts!.illusts.indexWhere((illust) => illust.id == _illust!.id);
    if (currentIndex == -1) return;

    // Calculate item width (including padding)
    const itemWidth = 120.0; // Base width of each item
    const itemPadding = 8.0; // Padding between items
    final offset = (itemWidth + itemPadding) * currentIndex;

    // Get the horizontal scroll width
    final scrollWidth = _horizontalScrollController.position.viewportDimension;

    // Center the item in the viewport
    final targetOffset =
        math.max(0, offset - (scrollWidth - itemWidth) / 2).toDouble();

    // Animate to the target offset
    _horizontalScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _savePage(int page) {
    if (_bucket != null && _illust != null) {
      _bucket!.writeState(context, page,
          identifier: 'carousel_page_${_illust!.id}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bucket = PageStorage.of(context);
    final savedPage = _bucket?.readState(context,
        identifier: 'carousel_page_${_illust?.id}') as int?;
    if (savedPage != null && savedPage < (_illust?.pageCount ?? 0)) {
      setState(() {
        _currentPage = savedPage;
        _carouselController.jumpToPage(savedPage);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentIllust();
    });
  }

  @override
  void initState() {
    super.initState();
    _illust = widget.illust;
    _userIllusts = widget.userIllusts;

    if (_illust == null && widget.illustId != null) {
      _loadIllust();
    }

    if (_userIllusts == null && _illust != null) {
      _loadUserIllusts();
    }

    if (_illust != null) {
      _loadRecommendIllusts();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIllust() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getIllustDetail(widget.illustId!);
      if (response.isSuccess) {
        setState(() {
          _illust = response.data;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendIllusts() async {
    if (_isLoadingRecommends || !_hasMoreRecommends || _illust == null) return;

    setState(() {
      _isLoadingRecommends = true;
    });

    try {
      final response = await _apiService.getRecommendIllusts(
          _illust!.id, _currentRecommendPage);

      if (response.isSuccess && response.data != null) {
        if (!mounted) return;
        setState(() {
          _recommendIllusts.addAll(response.data!.illusts);
          _currentRecommendPage++;
          _hasMoreRecommends = response.data!.hasNext;
          _isLoadingRecommends = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _hasMoreRecommends = false;
          _isLoadingRecommends = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasMoreRecommends = false;
        _isLoadingRecommends = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载推荐失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _downloadImage() async {
    try {
      // 显示下载进度对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '正在下载...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // 获取当前图片的URL
      var imageUrl = _apiService.getImageUrl(
        _illust!.image,
        _illust!.id,
        page: _currentPage,
        isOriginal: true,
      );

      // Try .png first, if 404 error occurs, try .jpg
      final dio = Dio();
      Response<List<int>> response;
      String fileExtension;

      try {
        response = await dio.get<List<int>>(
          '$imageUrl.png',
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              'Referer': 'https://pixivel.art/',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
          ),
        );
        fileExtension = 'png';
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          response = await dio.get<List<int>>(
            '$imageUrl.jpg',
            options: Options(
              responseType: ResponseType.bytes,
              headers: {
                'Referer': 'https://pixivel.art/',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              },
            ),
          );
          fileExtension = 'jpg';
        } else {
          rethrow;
        }
      }

      if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
        var status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要相册权限来保存图片')),
            );
          }
          return;
        }

        // Save to gallery using Gal
        await Gal.putImageBytes(Uint8List.fromList(response.data!),
            name: 'pixivel_${_illust!.id}_p$_currentPage.$fileExtension');

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片已保存到相册')),
        );
      } else {
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir == null) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法获取下载目录')),
            );
          }
          return;
        }

        final fileName = '${_illust!.id}_p$_currentPage.$fileExtension';
        final savePath = path.join(downloadDir.path, fileName);

        await File(savePath).writeAsBytes(response.data!);

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存到: $savePath'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框（如果存在）
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendSection() {
    if (_recommendIllusts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '推荐插画',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        WaterfallGrid(
          illusts: _recommendIllusts,
          isLoading: _isLoadingRecommends,
          onIllustTap: (illust) {
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: RouteSettings(name: 'illust_detail_${illust.id}'),
                builder: (context) => IllustDetailPage(
                  illust: illust,
                  isFromIllustDetail: true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_illust == null) {
      return const Scaffold(
        body: Center(
          child: Text('插画加载失败'),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: math.min(
                        MediaQuery.of(context).size.width *
                            0.65 *
                            (_illust!.height / _illust!.width),
                        MediaQuery.of(context).size.height,
                      ),
                      width: double.infinity,
                      child: Hero(
                        tag: _illust!.id,
                        child: Material(
                          color: Colors.transparent,
                          child: _buildIllustImage(isWideScreen: true),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 48,
                            width: 48,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              iconSize: 24,
                              icon: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            width: 48,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) =>
                                    route.settings.name
                                        ?.startsWith('illust_detail_') !=
                                    true);
                              },
                              iconSize: 24,
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: screenWidth * 0.3,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoadingRecommends &&
                      _hasMoreRecommends &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 800) {
                    _loadRecommendIllusts();
                  }
                  return true;
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildContent(),
                    const SizedBox(height: 24),
                    _buildRecommendSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingRecommends &&
              _hasMoreRecommends &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 800) {
            _loadRecommendIllusts();
          }
          return true;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: math.min(
                MediaQuery.of(context).size.width *
                    (_illust!.height / _illust!.width),
                MediaQuery.of(context).size.height * 0.9,
              ),
              pinned: true,
              actions: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 24,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) =>
                          route.settings.name?.startsWith('illust_detail_') !=
                          true);
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: _illust!.id,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildIllustImage(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildRecommendSection(),
            ),
          ],
        ),
      ),
    );
  }
}
