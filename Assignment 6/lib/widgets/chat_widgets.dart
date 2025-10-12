import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rive/rive.dart'; // Uncomment when you have a Rive file
import '../models/message.dart';
import '../providers/chat_providers.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final int index;
  final bool shouldAnimate;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.index,
    this.shouldAnimate = true,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 + (widget.index * 100).clamp(0, 400)),
    );
    
    // Different slide directions for user vs AI messages
    final slideOffset = widget.message.isUser 
        ? const Offset(1.0, 0.0)  // User messages slide from right
        : const Offset(-1.0, 0.0); // AI messages slide from left
    
    _slideAnimation = Tween<Offset>(
      begin: slideOffset,
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

    // Start animation with a slight delay for staggered effect
    // Only animate if shouldAnimate is true (for chat switches)
    if (widget.shouldAnimate) {
      Future.delayed(Duration(milliseconds: widget.index * 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      // For new messages in same chat, just show immediately
      _animationController.value = 1.0;
    }
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
        child: MessageBubble(message: widget.message),
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: message.isUser
                      ? SelectableText(
                          message.content.isEmpty && message.isStreaming ? 'Thinking...' : message.content,
                          style: TextStyle(
                            color: isUser 
                              ? theme.colorScheme.onPrimary 
                              : theme.colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content.isEmpty && message.isStreaming ? 'Thinking...' : message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                            code: TextStyle(
                              backgroundColor: theme.colorScheme.surface,
                              fontFamily: 'monospace',
                              fontSize: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                  ),
                  if (message.isStreaming && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        // child: CircularProgressIndicator(
                        //   strokeWidth: 2,
                        //   valueColor: AlwaysStoppedAnimation<Color>(
                        //     isUser 
                        //       ? theme.colorScheme.onPrimary 
                        //       : theme.colorScheme.onSurfaceVariant,
                        //   ),
                        // ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ...existing code...
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesList extends ConsumerStatefulWidget {
  const MessagesList({super.key});

  @override
  ConsumerState<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends ConsumerState<MessagesList>
    with SingleTickerProviderStateMixin {
  String? _lastChatId;
  int _lastMessageCount = 0;
  int _animationKey = 0;
  late AnimationController _chatSwitchController;
  late Animation<double> _fadeAnimation;
  bool _isChatSwitch = false;

  @override
  void initState() {
    super.initState();
    _chatSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chatSwitchController,
      curve: Curves.easeIn,
    ));
    _chatSwitchController.forward();
  }

  @override
  void dispose() {
    _chatSwitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentChat = ref.watch(currentChatProvider);
    final isLoading = ref.watch(isLoadingProvider);

    // Check if we switched to a different chat
    final currentChatId = currentChat?.id;
    final currentMessageCount = currentChat?.messages.length ?? 0;
    
    if (currentChatId != _lastChatId) {
      // This is a chat switch
      _lastChatId = currentChatId;
      _lastMessageCount = currentMessageCount;
      _animationKey++;
      _isChatSwitch = true;
      
      // Restart fade animation for chat switch
      _chatSwitchController.reset();
      _chatSwitchController.forward();
    } else if (currentMessageCount != _lastMessageCount) {
      // This is just a new message in the same chat
      _lastMessageCount = currentMessageCount;
      _isChatSwitch = false;
    }

    if (currentChat == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Color.fromARGB(24, 158, 158, 158),
            ),
            SizedBox(height: 16),
            Text(
              'Select a chat or start a new conversation',
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(0, 158, 158, 158),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        reverse: true,
        itemCount: currentChat.messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (isLoading && index == 0) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const LoadingMessageBubble(),
            );
          }

          final messageIndex = isLoading ? index - 1 : index;
          final message = currentChat.messages.reversed.toList()[messageIndex];
          
          return AnimatedMessageBubble(
            key: ValueKey('${currentChat.id}-$messageIndex-$_animationKey'),
            message: message,
            index: messageIndex,
            shouldAnimate: _isChatSwitch,
          );
        },
      ),
    );
  }
}

class LoadingMessageBubble extends StatefulWidget {
  const LoadingMessageBubble({super.key});

  @override
  State<LoadingMessageBubble> createState() => _LoadingMessageBubbleState();
}

class _LoadingMessageBubbleState extends State<LoadingMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: const RiveThinkingAnimation(),
        ),
      ),
    );
  }
}

class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    ref.read(isLoadingProvider.notifier).state = true;
    
    try {
      await ref.read(currentChatProvider.notifier).sendMessage(text.trim());
      // Refresh the chats list to show updated chat
      ref.read(allChatsProvider.notifier).refreshChats();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(isLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isLoading,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: (_isComposing && !isLoading) 
              ? () => _handleSubmitted(_controller.text)
              : null,
            mini: true,
            backgroundColor: (_isComposing && !isLoading)
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
            child: Icon(
              Icons.send,
              color: (_isComposing && !isLoading)
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, theme),
                const SizedBox(width: 4),
                _buildDot(1, theme),
                const SizedBox(width: 4),
                _buildDot(2, theme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    final delay = index * 0.2;
    final opacity = ((_animation.value + delay) % 1.0);
    
    return Opacity(
      opacity: opacity > 0.5 ? 1.0 - opacity : opacity * 2,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class RiveThinkingAnimation extends StatefulWidget {
  const RiveThinkingAnimation({super.key});

  @override
  State<RiveThinkingAnimation> createState() => _RiveThinkingAnimationState();
}

class _RiveThinkingAnimationState extends State<RiveThinkingAnimation> {
  RiveAnimationController? _controller;
  bool _hasRiveFile = false;

  @override
  void initState() {
    super.initState();
    _checkForRiveFile();
  }

  void _checkForRiveFile() {
    // Try to load the Rive file and check if it exists
    DefaultAssetBundle.of(context).load('assets/thinking_animal.riv').then((_) {
      if (mounted) {
        setState(() {
          _hasRiveFile = true;
          _controller = SimpleAnimation('idle'); // Replace with your animation name
        });
      }
    }).catchError((error) {
      // Rive file doesn't exist, use fallback animation
      if (mounted) {
        setState(() {
          _hasRiveFile = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRiveFile && _controller != null) {
      // Use actual Rive animation
      return SizedBox(
        width: 60,
        height: 40,
        child: RiveAnimation.asset(
          'assets/thinking_animal.riv',
          controllers: [_controller!],
          fit: BoxFit.contain,
        ),
      );
    } else {
      // Use fallback animation until Rive file is available
      return const _FallbackThinkingAnimation();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _FallbackThinkingAnimation extends StatefulWidget {
  const _FallbackThinkingAnimation();

  @override
  State<_FallbackThinkingAnimation> createState() => _FallbackThinkingAnimationState();
}

class _FallbackThinkingAnimationState extends State<_FallbackThinkingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation for the animal
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));

    // Rotation animation for playful movement
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _bounceController.repeat(reverse: true);
    _rotationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated animal emoji or Rive animation placeholder
        AnimatedBuilder(
          animation: Listenable.merge([_bounceController, _rotationController]),
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _bounceAnimation.value * -4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text(
                      '🐾', // Animal paw emoji as placeholder
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        
        // Animated dots
        AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (i * 100)),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 4,
                    height: 4 + (_bounceAnimation.value * 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.3 + (_bounceAnimation.value * 0.7),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        
        // Thinking text with typewriter effect
        AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            final progress = _bounceController.value;
            final text = 'Thinking';
            final visibleLength = (text.length * progress).round();
            final visibleText = text.substring(0, visibleLength);
            
            return Text(
              '$visibleText${'.' * ((progress * 3).round())}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            );
          },
        ),
      ],
    );
  }
}