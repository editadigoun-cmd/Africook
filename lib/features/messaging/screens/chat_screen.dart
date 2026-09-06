import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/message_bubble.dart';

final messagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, convId) {
  return ref.read(supabaseServiceProvider).getMessages(convId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MessageModel> _messages = [];
  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await ref
        .read(supabaseServiceProvider)
        .getMessages(widget.conversationId);
    setState(() {
      _messages.clear();
      _messages.addAll(msgs);
      _initialized = true;
    });
    _scrollToBottom();
    _markRead();
  }

  void _subscribeRealtime() {
    _channel = ref.read(supabaseServiceProvider).subscribeToMessages(
      widget.conversationId,
      (data) {
        final msg = MessageModel.fromJson(data);
        if (!_messages.any((m) => m.id == msg.id)) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
          _markRead();
        }
      },
    );
  }

  void _markRead() {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    ref
        .read(supabaseServiceProvider)
        .markMessagesRead(widget.conversationId, uid);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    _msgCtrl.clear();
    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId,
      senderId: uid,
      content: content,
      createdAt: DateTime.now(),
    );

    // Optimistic update
    setState(() => _messages.add(msg));
    _scrollToBottom();

    try {
      await ref.read(supabaseServiceProvider).sendMessage(msg);
    } catch (e) {
      setState(() => _messages.removeLast());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    final imageUrl = await CloudinaryService()
        .uploadImage(file, folder: 'messages');
    if (imageUrl == null) return;

    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId,
      senderId: uid,
      content: '📷 Image',
      messageType: MessageType.image,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(supabaseServiceProvider).sendMessage(msg);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: !_initialized
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Commencez la conversation !',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          return MessageBubble(
                            message: msg,
                            isMe: msg.senderId == uid,
                          );
                        },
                      ),
          ),

          // Typing indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: AppColors.primary),
                    onPressed: _sendImage,
                    tooltip: 'Envoyer une image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
