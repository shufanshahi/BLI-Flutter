import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'news_provider.dart';
import 'model/story.dart';
import 'model/comment.dart';

class NewsDetails extends StatefulWidget {
  final int storyId;

  const NewsDetails({super.key, required this.storyId});

  @override
  State<NewsDetails> createState() => _NewsDetailsState();
}

class _NewsDetailsState extends State<NewsDetails> {
  final NewsProvider _newsProvider = NewsProvider();
  Story? _story;
  List<Comment> _comments = [];
  bool _isLoadingStory = true;
  bool _isLoadingComments = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      setState(() {
        _isLoadingStory = true;
        _error = null;
      });

      final story = await _newsProvider.fetchStory(widget.storyId);
      setState(() {
        _story = story;
        _isLoadingStory = false;
      });

      // Load comments if available
      if (story.kids.isNotEmpty) {
        _loadComments();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingStory = false;
      });
    }
  }

  Future<void> _loadComments() async {
    if (_story?.kids.isEmpty ?? true) return;

    try {
      setState(() {
        _isLoadingComments = true;
      });

      // Load first 10 comments to avoid overwhelming the UI
      final commentIds = _story!.kids.take(10).toList();
      final comments = await _newsProvider.fetchComments(commentIds);

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    }
  }

  void _openUrl() {
    if (_story?.url != null) {
      // In a real app, you would use url_launcher package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL: ${_story!.url}'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _story!.url!));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story ${widget.storyId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_story?.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openUrl,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingStory) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              'Error loading story',
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
              onPressed: _loadStory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_story == null) {
      return const Center(
        child: Text('Story not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoryCard(),
          const SizedBox(height: 20),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _story!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'by ${_story!.by}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_story!.dateTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_story!.score} points',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_story!.kids.length} comments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (_story!.text != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _story!.text!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_story!.url != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _story!.url!,
                      style: TextStyle(
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoadingComments) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty && !_isLoadingComments)
          const Text('No comments available')
        else
          ..._comments.map((comment) => _buildCommentCard(comment)),
        if (_story!.kids.length > 10) ...[
          const SizedBox(height: 16),
          Text(
            'Showing ${_comments.length} of ${_story!.kids.length} comments',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  comment.by,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(comment.dateTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (comment.kids.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${comment.kids.length} replies',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
