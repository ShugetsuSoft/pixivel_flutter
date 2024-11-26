import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../models/illust.dart';
import '../services/api_service.dart';
import '../widgets/waterfall_grid.dart';
import 'illust_detail_page.dart';

class IllustratorProfilePage extends StatefulWidget {
  final int userId;
  final User? user;

  const IllustratorProfilePage({
    super.key,
    this.user,
    required this.userId,
  });

  @override
  State<IllustratorProfilePage> createState() => _IllustratorProfilePageState();
}

class _IllustratorProfilePageState extends State<IllustratorProfilePage> {
  final ApiService _apiService = ApiService();
  User? _user;
  final List<Illust> _illusts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUserIllusts();
  }

  Future<void> _loadUserIllusts() async {
    if (_isLoading || !_hasMore) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUserIllusts(
        widget.userId,
        page: _currentPage,
      );
      if (!mounted) return;
      if (response.isSuccess && response.data != null) {
        if (_user == null) {
          setState(() {
            _user = response.data!.user;
          });
        }
        setState(() {
          _illusts.addAll(response.data!.illusts);
          _currentPage++;
          _hasMore = response.data!.hasNext;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _illusts.clear();
    });
    await _loadUserIllusts();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoading &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              _hasMore) {
            _loadUserIllusts();
          }
          return true;
        },
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_user!.image.background != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return NotificationListener(
                        onNotification: (notification) {
                          // Handle drag for image expansion
                          return true;
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            InteractiveViewer(
                              panEnabled: false,
                              minScale: 1.0,
                              maxScale: 2.5,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black26,
                                          elevation: 0,
                                          leading: IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Hero(
                                              tag:
                                                  'background_image_${_user!.id}',
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    _apiService.getUserImageUrl(
                                                  _user!.image.background!,
                                                  _user!.id,
                                                ),
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'background_image_${_user!.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: _apiService.getUserImageUrl(
                                      _user!.image.background!,
                                      _user!.id,
                                    ),
                                    fit: BoxFit.cover,
                                    height: 160,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 4,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _apiService.getUserImageUrl(
                                _user!.image.url,
                                _user!.id,
                              ),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[800],
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _user!.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_user!.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _user!.bio,
                              style: TextStyle(
                                color: Colors.grey[400],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                WaterfallGrid(
                  illusts: _illusts,
                  isLoading: _isLoading && _hasMore,
                  onIllustTap: (illust) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings:
                            RouteSettings(name: 'illust_detail_${illust.id}'),
                        builder: (context) => IllustDetailPage(
                          illust: illust,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Top buttons
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        iconSize: 24,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        iconSize: 24,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
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
    );
  }
}
