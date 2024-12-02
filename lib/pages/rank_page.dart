import 'package:flutter/material.dart';
import 'package:pixivel_flutter/models/illust.dart';
import 'package:pixivel_flutter/pages/illust_detail_page.dart';
import 'package:pixivel_flutter/services/api_service.dart';
import 'package:pixivel_flutter/widgets/waterfall_grid.dart';
import 'package:intl/intl.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final List<Illust> _illusts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  bool _hasError = false;
  String _errorMessage = '';

  String _selectedMode = 'daily';
  String _selectedContent = 'all';
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _selectedDate =
        _getFormattedDate(DateTime.now().subtract(const Duration(days: 3)));
    _loadIllusts();
  }

  String _getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadIllusts() async {
    if (_isLoading || !_hasMore) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _apiService.getRankings(
        mode: _selectedMode,
        date: _selectedDate,
        content: _selectedContent,
        page: _currentPage,
      );

      if (response.isSuccess && response.data != null) {
        if (!mounted) return;
        setState(() {
          _illusts.addAll(response.data!.illusts);
          _hasMore = response.data!.hasNext;
          _currentPage++;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasMore = false;
          _hasError = true;
          if (response.isBanned) {
            _errorMessage = '内容已被封禁';
          } else if (response.shouldRetry) {
            _errorMessage = '请稍后重试';
          } else if (response.message != null) {
            _errorMessage = '加载失败: ${response.message}';
          } else {
            _errorMessage = '加载失败';
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              action: SnackBarAction(
                label: '重试',
                onPressed: _loadIllusts,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _hasError = true;
        _errorMessage = '加载失败';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('加载失败'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadIllusts,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ApiService.rankModes[_selectedContent]!.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Text('排行榜'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              initialValue: _selectedContent,
              onSelected: (String content) {
                if (!mounted) return;
                setState(() {
                  _selectedContent = content;
                  _selectedMode = ApiService.rankModes[_selectedContent]![0];
                  _illusts.clear();
                  _currentPage = 0;
                  _hasMore = true;
                });
                _loadIllusts();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'all',
                  child: Text('全部'),
                ),
                const PopupMenuItem<String>(
                  value: 'illust',
                  child: Text('插画'),
                ),
                const PopupMenuItem<String>(
                  value: 'manga',
                  child: Text('漫画'),
                ),
                const PopupMenuItem<String>(
                  value: 'ugoira',
                  child: Text('动图'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedContent == 'all'
                        ? '全部'
                        : _selectedContent == 'illust'
                            ? '插画'
                            : _selectedContent == 'manga'
                                ? '漫画'
                                : '动图'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 3)),
                  firstDate: DateTime(2007, 9, 10),
                  lastDate: DateTime.now().subtract(const Duration(days: 3)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = _getFormattedDate(picked);
                    _illusts.clear();
                    _currentPage = 0;
                    _hasMore = true;
                  });
                  _loadIllusts();
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: ApiService.rankModes[_selectedContent]!.map((mode) {
              String label;
              switch (mode) {
                case 'daily':
                  label = '每日';
                  break;
                case 'weekly':
                  label = '每周';
                  break;
                case 'monthly':
                  label = '每月';
                  break;
                case 'rookie':
                  label = '新人';
                  break;
                case 'original':
                  label = '原创';
                  break;
                case 'male':
                  label = '男性向';
                  break;
                case 'female':
                  label = '女性向';
                  break;
                default:
                  label = mode;
              }
              return Tab(text: label);
            }).toList(),
            onTap: (index) {
              final mode = ApiService.rankModes[_selectedContent]![index];
              if (_selectedMode != mode) {
                setState(() {
                  _selectedMode = mode;
                  _illusts.clear();
                  _currentPage = 0;
                  _hasMore = true;
                });
                _loadIllusts();
              }
            },
            controller: TabController(
              length: ApiService.rankModes[_selectedContent]!.length,
              vsync: this,
              initialIndex: ApiService.rankModes[_selectedContent]!
                  .indexOf(_selectedMode),
            ),
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoading &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                _hasMore) {
              _loadIllusts();
            }
            return true;
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_hasError)
                Center(
                  child: Text(_errorMessage),
                ),
              const SizedBox(
                height: 8,
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
        ),
      ),
    );
  }
}
