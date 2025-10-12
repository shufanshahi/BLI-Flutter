import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/chat_widgets.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  bool _isSidebarVisible = true;
  late AnimationController _sidebarAnimationController;
  late Animation<Offset> _sidebarSlideAnimation;

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sidebarSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start with animation when app opens
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
    
    if (_isSidebarVisible) {
      _sidebarAnimationController.forward();
    } else {
      _sidebarAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChat = ref.watch(currentChatProvider);
    final isServerAvailable = ref.watch(isServerAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (!_isSidebarVisible)
              IconButton(
                onPressed: _toggleSidebar,
                icon: const Icon(Icons.menu),
              ),
            Expanded(
              child: Text(
                currentChat?.name ?? 'Chat Assistant',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Server status indicator
            isServerAvailable.when(
              data: (available) => Icon(
                Icons.circle,
                size: 12,
                color: available ? Colors.green : Colors.red,
              ),
              loading: () => const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
              error: (_, __) => const Icon(
                Icons.circle,
                size: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSidebarVisible && MediaQuery.of(context).size.width < 800)
            IconButton(
              onPressed: _toggleSidebar,
              icon: const Icon(Icons.close),
            ),
          if (MediaQuery.of(context).size.width >= 800)
            IconButton(
              onPressed: _toggleSidebar,
              icon: Icon(_isSidebarVisible ? Icons.close : Icons.menu),
            ),
        ],
      ),
      body: Row(
        children: [
          // Animated Sidebar
          if (_isSidebarVisible)
            SlideTransition(
              position: _sidebarSlideAnimation,
              child: const ChatSidebar(),
            ),
          
          // Main chat area
          Expanded(
            child: Column(
              children: [
                // Messages list
                const Expanded(
                  child: MessagesList(),
                ),
                
                // Message input
                const MessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveChatLayout extends ConsumerWidget {
  const ResponsiveChatLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // Mobile layout - use navigation
      return const MobileChatLayout();
    } else {
      // Desktop/tablet layout
      return const ChatScreen();
    }
  }
}

class MobileChatLayout extends ConsumerWidget {
  const MobileChatLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChat = ref.watch(currentChatProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(currentChat?.name ?? 'Chat Assistant'),
        leading: IconButton(
          onPressed: () {
            _showChatsList(context);
          },
          icon: const Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(currentChatProvider.notifier).createNewChat();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: MessagesList()),
          MessageInput(),
        ],
      ),
    );
  }

  void _showChatsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 500),
      ),
      builder: (context) => const AnimatedChatListModal(),
    );
  }
}

class AnimatedChatListModal extends ConsumerStatefulWidget {
  const AnimatedChatListModal({super.key});

  @override
  ConsumerState<AnimatedChatListModal> createState() => _AnimatedChatListModalState();
}

class _AnimatedChatListModalState extends ConsumerState<AnimatedChatListModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _listController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    
    // Delay the list items animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _listController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final allChats = ref.watch(allChatsProvider);
                      
                      if (allChats.isEmpty) {
                        return const Center(
                          child: Text('No chats yet'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: allChats.length,
                        itemBuilder: (context, index) {
                          final chat = allChats[index];
                          return AnimatedChatListItem(
                            chat: chat,
                            index: index,
                            onTap: () {
                              ref.read(currentChatProvider.notifier).loadChat(chat.id);
                              Navigator.of(context).pop();
                            },
                            onDelete: () {
                              ref.read(allChatsProvider.notifier).deleteChat(chat.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedChatListItem extends StatefulWidget {
  final dynamic chat;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AnimatedChatListItem({
    super.key,
    required this.chat,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<AnimatedChatListItem> createState() => _AnimatedChatListItemState();
}

class _AnimatedChatListItemState extends State<AnimatedChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200 + (widget.index * 50).clamp(0, 300)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Staggered animation start
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListTile(
          title: Text(widget.chat.name),
          subtitle: Text(
            widget.chat.lastMessagePreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: widget.onTap,
          trailing: IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ),
    );
  }
}