import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/recipe_model.dart';

class CookingModeScreen extends StatefulWidget {
  final RecipeModel recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with TickerProviderStateMixin {
  int _current = 0;
  bool _timerRunning = false;
  int _secondsLeft = 0;
  Timer? _timer;
  late final PageController _pageController;
  late AnimationController _progressController;

  List<RecipeStep> get _steps => widget.recipe.steps;
  RecipeStep get _step => _steps[_current];
  bool get _hasTimer => _step.durationMinutes != null && _step.durationMinutes! > 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _resetTimer();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timerRunning = false;
    _secondsLeft = (_step.durationMinutes ?? 0) * 60;
    _progressController.value = 1.0;
  }

  void _startTimer() {
    if (_secondsLeft <= 0) return;
    setState(() => _timerRunning = true);
    final total = _secondsLeft.toDouble();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        setState(() => _timerRunning = false);
        _onTimerDone();
        return;
      }
      setState(() => _secondsLeft--);
      _progressController.value = _secondsLeft / total;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _onTimerDone() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⏰ Temps écoulé !',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Étape ${_step.stepNumber} terminée.',
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_current < _steps.length - 1) _goToStep(_current + 1);
            },
            child: const Text('Étape suivante'),
          ),
        ],
      ),
    );
  }

  void _goToStep(int index) {
    _timer?.cancel();
    setState(() => _current = index);
    _resetTimer();
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _steps.length;
    if (total == 0) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Aucune étape disponible',
              style: TextStyle(color: Colors.white70, fontFamily: 'Nunito')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page swipe between steps
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (i) {
              if (i != _current) {
                _timer?.cancel();
                setState(() => _current = i);
                _resetTimer();
              }
            },
            itemBuilder: (_, i) => _StepPage(
              step: _steps[i],
              index: i,
              total: total,
              recipeName: widget.recipe.title,
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  // Progress dots
                  Row(
                    children: List.generate(
                      total,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _current ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.primary
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_current + 1} / $total',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer
                  if (_hasTimer) ...[
                    _TimerWidget(
                      secondsLeft: _secondsLeft,
                      totalSeconds: (_step.durationMinutes ?? 0) * 60,
                      running: _timerRunning,
                      formatTime: _formatTime,
                      onStart: _startTimer,
                      onPause: _pauseTimer,
                      onReset: () => setState(_resetTimer),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Prev / Next
                  Row(
                    children: [
                      Expanded(
                        child: _NavButton(
                          label: _current > 0 ? '← Précédente' : '',
                          onTap: _current > 0
                              ? () => _goToStep(_current - 1)
                              : null,
                          secondary: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _current < total - 1
                            ? _NavButton(
                                label: 'Suivante →',
                                onTap: () => _goToStep(_current + 1),
                              )
                            : _NavButton(
                                label: '🎉 Terminé !',
                                onTap: () => _showFinished(),
                                primary: true,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinished() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Félicitations !',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 20)),
        content: Text(
          'Vous avez terminé la recette "${widget.recipe.title}" !',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retour à la recette'),
          ),
        ],
      ),
    );
  }
}

// ── Step page ────────────────────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  final RecipeStep step;
  final int index;
  final int total;
  final String recipeName;

  const _StepPage({
    required this.step,
    required this.index,
    required this.total,
    required this.recipeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipeName,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Étape ${step.stepNumber}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primary.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    step.instruction,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              if (step.durationMinutes != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${step.durationMinutes} min',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white54,
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer widget ─────────────────────────────────────────────────────────────

class _TimerWidget extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final bool running;
  final String Function(int) formatTime;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _TimerWidget({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.running,
    required this.formatTime,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? secondsLeft / totalSeconds : 0.0;
    final isExpired = secondsLeft <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    isExpired ? Colors.red : AppColors.primary),
                  strokeWidth: 4,
                ),
                Text(
                  isExpired ? '00:00' : formatTime(secondsLeft),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: isExpired ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Temps écoulé' : formatTime(secondsLeft),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isExpired ? Colors.red : Colors.white,
                  ),
                ),
                Text(
                  'Minuterie · ${formatTime(totalSeconds)}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white54),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (!isExpired)
                GestureDetector(
                  onTap: running ? onPause : onStart,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      running ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onReset,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.replay,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav button ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final bool primary;

  const _NavButton({
    required this.label,
    this.onTap,
    this.secondary = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty || onTap == null) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary
              : secondary
                  ? Colors.white12
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: secondary ? Border.all(color: Colors.white24) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: (primary || secondary) ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
