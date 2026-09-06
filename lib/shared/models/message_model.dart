import 'recipe_model.dart';

class ConversationModel {
  final String id;
  final String userAId;
  final String userBId;
  final String? recipeId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final UserModel? otherUser;
  final MessageModel? lastMessage;
  final RecipeModel? linkedRecipe;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.userAId,
    required this.userBId,
    this.recipeId,
    required this.lastMessageAt,
    required this.createdAt,
    this.otherUser,
    this.lastMessage,
    this.linkedRecipe,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isUserA = json['user_a_id'] == currentUserId;
    final otherUserData = isUserA ? json['user_b'] : json['user_a'];

    return ConversationModel(
      id: json['id'] as String,
      userAId: json['user_a_id'] as String,
      userBId: json['user_b_id'] as String,
      recipeId: json['recipe_id'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUser: otherUserData != null
          ? UserModel.fromJson(otherUserData as Map<String, dynamic>)
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType messageType;
  final String? imageUrl;
  final String? sharedRecipeId;
  final bool isRead;
  final DateTime createdAt;
  final RecipeModel? sharedRecipe;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.sharedRecipeId,
    this.isRead = false,
    required this.createdAt,
    this.sharedRecipe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
        imageUrl: json['image_url'] as String?,
        sharedRecipeId: json['shared_recipe_id'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType.value,
        'image_url': imageUrl,
        'shared_recipe_id': sharedRecipeId,
      };
}

enum MessageType {
  text('text'),
  image('image'),
  recipeShare('recipe_share');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String v) =>
      MessageType.values.firstWhere((e) => e.value == v, orElse: () => MessageType.text);
}
