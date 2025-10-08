import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'news_provider.dart';
import 'news_details.dart';
import 'model/story_type.dart';
import 'model/story.dart';
import 'database_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsProvider _newsProvider = NewsProvider();
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();

  List<int> _allStoryIds = [];
  List<Story> _stories = [];
  bool _isLoadingIds = true;
  bool _isLoadingMore = false;
  bool _hasMoreStories = true;
  String? _error;

  StoryType _currentStoryType = StoryType.top;
  int _selectedNavIndex = 0;
  static const int _batchSize = 20;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreStories) {
      _loadMoreStories();
    }
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        _isLoadingIds = true;
        _error = null;
        _stories.clear();
        _hasMoreStories = true;
      });

      // First check if we have cached story IDs
      final cachedIds = await _databaseService.getCachedStoryIds(_currentStoryType);
      List<int> storyIds;

      if (cachedIds != null) {
        storyIds = cachedIds;
        setState(() {
          _allStoryIds = storyIds;
          _isLoadingIds = false;
        });
      } else {
        // Fetch from API if not cached
        storyIds = await _newsProvider.fetchStoryIds(_currentStoryType);
        setState(() {
          _allStoryIds = storyIds;
          _isLoadingIds = false;
        });
      }

      await _loadMoreStories();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingIds = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore || !_hasMoreStories) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final startIndex = _stories.length;
      final endIndex = (startIndex + _batchSize).clamp(0, _allStoryIds.length);
      final batchIds = _allStoryIds.sublist(startIndex, endIndex);

      if (batchIds.isEmpty) {
        setState(() {
          _hasMoreStories = false;
          _isLoadingMore = false;
        });
        return;
      }

      // First try to get stories from cache
      final cachedStories = await _databaseService.getCachedStories(batchIds);
      List<Story> newStories = List.from(cachedStories);

      // Find which stories are missing from cache
      final cachedIds = cachedStories.map((story) => story.id).toSet();
      final missingIds = batchIds.where((id) => !cachedIds.contains(id)).toList();

      // Fetch missing stories from API
      if (missingIds.isNotEmpty) {
        try {
          final fetchedStories = await _newsProvider.fetchStories(missingIds);
          newStories.addAll(fetchedStories);

          // Save fetched stories to database
          await _databaseService.saveStories(fetchedStories);
        } catch (e) {
          debugPrint('Failed to fetch some stories: $e');
          // Continue with cached stories only
        }
      }

      // Sort stories by their order in the original list
      newStories.sort((a, b) {
        final aIndex = batchIds.indexOf(a.id);
        final bIndex = batchIds.indexOf(b.id);
        return aIndex.compareTo(bIndex);
      });

      setState(() {
        _stories.addAll(newStories);
        _isLoadingMore = false;
        _hasMoreStories = _stories.length < _allStoryIds.length;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  void _onNavItemTapped(int index) {
    final storyTypes = [StoryType.top, StoryType.best, StoryType.newStories];
    if (index != _selectedNavIndex) {
      setState(() {
        _selectedNavIndex = index;
        _currentStoryType = storyTypes[index];
      });
      _loadStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStoryType.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Top',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Best',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.new_releases),
            label: 'New',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingIds) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading stories',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty && !_isLoadingMore) {
      return const Center(
        child: Text('No stories found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _stories.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _stories.length) {
            return _buildShimmerLoadingItem();
          }

          final story = _stories[index];
          final globalIndex = index + 1;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '$globalIndex',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                story.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'by ${story.by}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.thumb_up, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${story.score}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetails(storyId: story.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        children: List.generate(20, (index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Container(),
              ),
              title: Container(
                height: 16,
                color: Colors.grey[300],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShimmerLoadingItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Container(),
          ),
          title: Container(
            height: 16,
            color: Colors.grey[300],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 100,
                color: Colors.grey[300],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
