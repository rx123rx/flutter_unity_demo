import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_unity_demo/models/chat_message.dart';
import 'package:flutter_unity_demo/widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();

  // 缓存键盘高度，避免频繁重建
  double _cachedKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    // 设置竖屏模式，防止键盘弹出时旋转
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // 恢复屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // 模拟 Unity 角色回复
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: "我收到了你的消息: $text",
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });

          _scrollToBottom();

          // 调用 Unity 控制模型表情
          sendToUnity("Character", "PlayExpression", "Happy");
        }
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void onMessageFromUnity(String message) {
    // 处理从 Unity 发送的消息
    if (kDebugMode) {
      debugPrint('Received message from Unity: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 MediaQuery 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 性能优化：只有当键盘高度显著变化时才更新
    if ((keyboardHeight - _cachedKeyboardHeight).abs() > 1.0) {
      _cachedKeyboardHeight = keyboardHeight;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时调整页面大小
      body: Stack(
        fit: StackFit.expand, // 让 Stack 充满整个屏幕
        children: [
          // Unity 3D 背景 - 使用 Positioned 防止变形
          Positioned.fill(
            child: IgnorePointer(
              child: EmbedUnity(
                onMessageFromUnity: onMessageFromUnity,
              ),
            ),
          ),

          // 半透明遮罩 - 使用 const 避免重建
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.3),
                    Color.fromRGBO(0, 0, 0, 0.0),
                    Color.fromRGBO(0, 0, 0, 0.5),
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // 聊天界面 - 使用 AnimatedPositioned 平滑动画
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            bottom: _cachedKeyboardHeight,
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildMessageList(),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'Chat with Unity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // 性能优化：使用 const 构造函数，避免不必要的重建
        return MessageBubble(key: ValueKey(_messages[index].timestamp), message: _messages[index]);
      },
      // 性能优化：启用自动保留状态
      cacheExtent: 500,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }

  Widget _buildInputField() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              // 性能优化：禁用输入时的自动滚动
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
