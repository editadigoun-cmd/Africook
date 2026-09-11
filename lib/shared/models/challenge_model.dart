class ChallengeSubmissionModel {
  final String id;
  final String challengeId;
  final String userId;
  final String imageUrl;
  final String? description;
  final int votesCount;
  final DateTime? createdAt;
  final String? authorName;
  final String? authorAvatar;
  bool hasVoted;

  ChallengeSubmissionModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.imageUrl,
    this.description,
    this.votesCount = 0,
    this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.hasVoted = false,
  });

  factory ChallengeSubmissionModel.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;
    return ChallengeSubmissionModel(
      id: j['id'] as String,
      challengeId: j['challenge_id'] as String,
      userId: j['user_id'] as String,
      imageUrl: j['image_url'] as String,
      description: j['description'] as String?,
      votesCount: (j['votes_count'] as num?)?.toInt() ?? 0,
      createdAt: j['created_at'] != null ? DateTime.parse(j['created_at'] as String) : null,
      authorName: user?['full_name'] as String?,
      authorAvatar: user?['avatar_url'] as String?,
    );
  }
}

class ChallengeModel {
  final String id;
  final String title;
  final String? description;
  final String? recipeId;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final List<ChallengeSubmissionModel> submissions;

  ChallengeModel({
    required this.id,
    required this.title,
    this.description,
    this.recipeId,
    this.imageUrl,
    required this.startsAt,
    required this.endsAt,
    this.isActive = true,
    this.submissions = const [],
  });

  bool get isOngoing => isActive && DateTime.now().isBefore(endsAt);

  Duration get timeLeft => endsAt.difference(DateTime.now());

  factory ChallengeModel.fromJson(Map<String, dynamic> j) => ChallengeModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        recipeId: j['recipe_id'] as String?,
        imageUrl: j['image_url'] as String?,
        startsAt: DateTime.parse(j['starts_at'] as String),
        endsAt: DateTime.parse(j['ends_at'] as String),
        isActive: j['is_active'] as bool? ?? true,
      );
}
