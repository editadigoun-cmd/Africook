import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/challenge_model.dart';
import '../../../shared/providers/auth_provider.dart';

final activeChallengeProvider =
    FutureProvider<ChallengeModel?>((ref) async {
  final svc = ref.read(supabaseServiceProvider);
  final data = await svc.getActiveChallenge();
  if (data == null) return null;
  final model = ChallengeModel.fromJson(data);
  final submissions =
      await svc.getChallengeSubmissions(model.id);
  final uid = SupabaseService.currentUserId;
  final List<ChallengeSubmissionModel> subs = [];
  for (final s in submissions) {
    final sub = ChallengeSubmissionModel.fromJson(s as Map<String, dynamic>);
    if (uid != null) {
      sub.hasVoted = await svc.hasVotedSubmission(sub.id, uid);
    }
    subs.add(sub);
  }
  return ChallengeModel(
    id: model.id,
    title: model.title,
    description: model.description,
    recipeId: model.recipeId,
    imageUrl: model.imageUrl,
    startsAt: model.startsAt,
    endsAt: model.endsAt,
    isActive: model.isActive,
    submissions: subs,
  );
});

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeChallengeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Défi de la semaine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (challenge) {
          if (challenge == null) {
            return const Center(
              child: Text('Aucun défi en cours',
                  style: TextStyle(color: AppColors.textLight, fontSize: 16)),
            );
          }
          return _ChallengeBody(challenge: challenge);
        },
      ),
    );
  }
}

class _ChallengeBody extends ConsumerStatefulWidget {
  final ChallengeModel challenge;
  const _ChallengeBody({required this.challenge});

  @override
  ConsumerState<_ChallengeBody> createState() => _ChallengeBodyState();
}

class _ChallengeBodyState extends ConsumerState<_ChallengeBody> {
  late List<ChallengeSubmissionModel> _submissions;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _submissions = List.from(widget.challenge.submissions);
  }

  Duration get _timeLeft => widget.challenge.endsAt.difference(DateTime.now());

  String get _timeLeftStr {
    final d = _timeLeft;
    if (d.isNegative) return 'Terminé';
    if (d.inDays > 0) return '${d.inDays}j ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  Future<void> _submitEntry() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Connectez-vous pour participer')));
      return;
    }
    final already = _submissions.any((s) => s.userId == uid);
    if (already) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vous avez déjà soumis votre version !')));
      return;
    }

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1200);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();

    String? desc;
    if (mounted) {
      desc = await _showDescDialog();
    }

    setState(() => _submitting = true);
    try {
      final url = await CloudinaryService().uploadImageBytes(bytes,
          fileName: 'challenge_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (url == null) throw Exception('Upload échoué');
      await ref.read(supabaseServiceProvider).submitChallenge(
            challengeId: widget.challenge.id,
            userId: uid,
            imageUrl: url,
            description: desc,
          );
      ref.invalidate(activeChallengeProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participation envoyée ! Bonne chance 🎉')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<String?> _showDescDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Décrivez votre plat'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Astuce secrète, variante régionale…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Passer')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _vote(ChallengeSubmissionModel sub) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final newVote = !sub.hasVoted;
    setState(() {
      sub.hasVoted = newVote;
      // ignore: invalid_use_of_protected_member
    });
    try {
      await ref.read(supabaseServiceProvider).voteSubmission(sub.id, uid, newVote);
      ref.invalidate(activeChallengeProvider);
    } catch (_) {
      setState(() => sub.hasVoted = !newVote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(c),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _submitting
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Participer — publier ma version'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: c.isOngoing ? _submitEntry : null,
                  ),
          ),
          const SizedBox(height: 24),
          if (_submissions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Soyez le premier à participer !',
                      style: TextStyle(color: AppColors.textLight, fontSize: 15))),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${_submissions.length} participation(s)',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark)),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _submissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _SubmissionCard(sub: _submissions[i], onVote: _vote),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ChallengeModel c) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF374151)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('🏆 DÉFI EN COURS',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('⏱ $_timeLeftStr',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(c.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          if (c.description != null) ...[
            const SizedBox(height: 8),
            Text(c.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final ChallengeSubmissionModel sub;
  final void Function(ChallengeSubmissionModel) onVote;

  const _SubmissionCard({required this.sub, required this.onVote});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              sub.imageUrl,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.divider,
                  child: const Icon(Icons.broken_image, size: 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: sub.authorAvatar != null
                          ? NetworkImage(sub.authorAvatar!)
                          : null,
                      child: sub.authorAvatar == null
                          ? const Icon(Icons.person, size: 18, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(sub.authorName ?? 'Anonyme',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
                if (sub.description != null && sub.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(sub.description!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textLight)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onVote(sub),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sub.hasVoted
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sub.hasVoted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: sub.hasVoted
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('${sub.votesCount}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: sub.hasVoted
                                        ? Colors.white
                                        : AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
