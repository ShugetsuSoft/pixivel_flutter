import 'package:flutter/material.dart';
import '../models/illust.dart';
import '../services/api_service.dart';
import '../widgets/waterfall_grid.dart';
import 'illust_detail_page.dart';
import '../models/user.dart';

class SearchPage extends StatefulWidget {
  final String? initialSearchText;

  const SearchPage({
    super.key,
    this.initialSearchText,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum SearchType {
  illustration,
  illustrator,
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  late TabController _tabController;

  SearchType _searchType = SearchType.illustration;

  List<Illust>? _illustSearchResults;
  List<User>? _illustratorSearchResults;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    if (widget.initialSearchText != null &&
        widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
      // Perform search in the next frame after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(reset: true);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    _performSearch(reset: true);
  }

  String get _currentSort {
    switch (_tabController.index) {
      case 0:
        return 'relevent';
      case 1:
        return 'popular';
      case 2:
        return 'time';
      default:
        return 'relevent';
    }
  }

  Future<void> _performSearch({bool reset = false}) async {
    if (_isLoading || _searchController.text.isEmpty) return;
    if (reset) {
      setState(() {
        _illustSearchResults = null;
        _illustratorSearchResults = null;
        _currentPage = 0;
        _hasMore = true;
        _error = null;
      });
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_searchType == SearchType.illustration) {
        final response = await _apiService.searchIllusts(
          _searchController.text,
          page: _currentPage,
          sort: _currentSort,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            if (_illustSearchResults == null || reset) {
              _illustSearchResults = response.data!.illusts;
            } else {
              _illustSearchResults!.addAll(response.data!.illusts);
            }
            _hasMore = response.data!.hasNext;
            _currentPage++;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.message ?? '搜索失败';
            _isLoading = false;
          });
        }
      } else {
        final response = await _apiService.searchIllustrators(
          _searchController.text,
          page: _currentPage,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            if (_illustratorSearchResults == null || reset) {
              _illustratorSearchResults = response.data!.users;
            } else {
              _illustratorSearchResults!.addAll(response.data!.users);
            }
            _hasMore = response.data!.hasNext;
            _currentPage++;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.message ?? '搜索失败';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('搜索'),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _performSearch(reset: true),
                  ),
                ),
                onSubmitted: (_) => _performSearch(reset: true),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<SearchType>(
                value: _searchType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: SearchType.illustration,
                    child: Text('插画'),
                  ),
                  DropdownMenuItem(
                    value: SearchType.illustrator,
                    child: Text('画师'),
                  ),
                ],
                onChanged: (SearchType? value) {
                  if (value != null) {
                    setState(() {
                      _searchType = value;
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(reset: true);
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '相关'),
            Tab(text: '热门'),
            Tab(text: '最新'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchType == SearchType.illustration &&
            _illustSearchResults == null ||
        _searchType == SearchType.illustrator &&
            _illustratorSearchResults == null) {
      return Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('输入关键词开始搜索'),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(reset: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading &&
            _hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _performSearch();
        }
        return true;
      },
      child: _searchType == SearchType.illustration
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                if (_illustSearchResults!.isEmpty && _isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_illustSearchResults!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('没有找到相关作品'),
                    ),
                  ),
                WaterfallGrid(
                  illusts: _illustSearchResults!,
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
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                if (_illustratorSearchResults!.isEmpty && _isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_illustratorSearchResults!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('没有找到相关画师'),
                    ),
                  ),
              ],
            ),
    );
  }
}
