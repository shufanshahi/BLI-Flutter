import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../providers/chat_providers.dart';

class ChatSidebar extends ConsumerStatefulWidget {
  const ChatSidebar({super.key});

  @override
  ConsumerState<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends ConsumerState<ChatSidebar> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
    });
    _searchController.clear();
    ref.read(allChatsProvider.notifier).loadAllChats();
  }

  void _onSearchChanged(String query) {
    ref.read(allChatsProvider.notifier).searchChats(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allChats = ref.watch(allChatsProvider);
    final currentChat = ref.watch(currentChatProvider);
    final isServerAvailable = ref.watch(isServerAvailableProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with New Chat button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!_isSearching) ...[
                  Expanded(
                    child: AnimatedNewChatButton(
                      onPressed: () {
                        ref.read(currentChatProvider.notifier).createNewChat();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _startSearch,
                    icon: const Icon(Icons.search),
                  ),
                ] else ...[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search chats...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _stopSearch,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
          ),

          // Server status indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isServerAvailable.when(
                data: (available) => available 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                loading: () => Colors.orange.withOpacity(0.1),
                error: (_, __) => Colors.red.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isServerAvailable.when(
                    data: (available) => available ? Colors.green : Colors.red,
                    loading: () => Colors.orange,
                    error: (_, __) => Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isServerAvailable.when(
                      data: (available) => available 
                        ? 'LM Studio Connected'
                        : 'LM Studio Disconnected',
                      loading: () => 'Checking...',
                      error: (_, __) => 'Connection Error',
                    ),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chats list
          Expanded(
            child: allChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching ? 'No chats found' : 'No chats yet',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: allChats.length,
                  itemBuilder: (context, index) {
                    final chat = allChats[index];
                    final isSelected = currentChat?.id == chat.id;

                    return ChatTile(
                      chat: chat,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(currentChatProvider.notifier).loadChat(chat.id);
                      },
                      onDelete: () {
                        _showDeleteConfirmation(context, chat);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${chat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(allChatsProvider.notifier).deleteChat(chat.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ChatTile extends StatefulWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatTile({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected 
            ? theme.colorScheme.primaryContainer
            : (_isHovered ? theme.colorScheme.surfaceVariant : null),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: widget.onTap,
          title: Text(
            widget.chat.name,
            style: TextStyle(
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              color: widget.isSelected 
                ? theme.colorScheme.onPrimaryContainer
                : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chat.lastMessagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isSelected 
                    ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(widget.chat.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isSelected 
                    ? theme.colorScheme.onPrimaryContainer.withOpacity(0.5)
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          trailing: _isHovered
            ? IconButton(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              )
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chatDate = DateTime(date.year, date.month, date.day);

    if (chatDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (chatDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

class AnimatedNewChatButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedNewChatButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<AnimatedNewChatButton> createState() => _AnimatedNewChatButtonState();
}

class _AnimatedNewChatButtonState extends State<AnimatedNewChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20500),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton.icon(
          onPressed: null, // Handled by GestureDetector
          icon: const Icon(Icons.add),
          label: const Text('New Chat'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      ),
    );
  }
}