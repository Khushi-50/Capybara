import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../providers/quest_provider.dart';
import '../models/quest_models.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Header slide-down
  late final AnimationController _headerCtrl;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerFade;

  // Global pulse for the active (unlocked, not completed) node
  late final AnimationController _pulseCtrl;

  // Shimmer for locked nodes
  late final AnimationController _shimmerCtrl;

  // Track whether the map has appeared yet (drives stagger)
  bool _mapVisible = false;

  @override
  void initState() {
    super.initState();

    // Header: slides down + fades in over 600ms
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);

    // Pulse: infinite slow breathe for the active node ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Shimmer: sweeps right forever for locked nodes
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _headerCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<QuestProvider>(context, listen: false);
      if (provider.courseMap.isEmpty && !provider.isLoading) {
        await provider.loadUserData();
      }
      await NotificationService().onAppOpen(
        didActivityToday: provider.didActivityToday,
        streak: provider.streak,
      );
      if (mounted) setState(() => _mapVisible = true);
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMap(context, provider),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(context, provider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MAP ────────────────────────────────────────────────────────────────────
  Widget _buildMap(BuildContext context, QuestProvider provider) {
    if (provider.isLoading && provider.courseMap.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.courseMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Unable to connect',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.loadUserData,
              child: const Text(
                'RETRY',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // Collect all subtopics into a flat list with chapter boundaries
    final items = <_MapItem>[];
    for (final chapter in provider.courseMap) {
      items.add(_MapItem.header(chapter.chapterName));
      for (int i = 0; i < chapter.subtopics.length; i++) {
        items.add(_MapItem.node(chapter.subtopics[i], i));
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 220),
          ...items.asMap().entries.map((e) {
            final delay = Duration(milliseconds: 80 * e.key);
            final item = e.value;
            if (item.isHeader) {
              return _AnimatedEntrance(
                delay: delay,
                visible: _mapVisible,
                child: _ChapterBanner(title: item.chapterName!),
              );
            }
            final subtopic = item.subtopic!;
            final status = provider.getSubtopicStatus(subtopic.subtopicId);
            final isLocked = status == 'locked';

            // Zig-zag alignment: center / left / center / right
            Alignment alignment = Alignment.center;
            if (item.indexInChapter % 4 == 1) alignment = Alignment.centerLeft;
            if (item.indexInChapter % 4 == 3) alignment = Alignment.centerRight;

            return _AnimatedEntrance(
              delay: delay,
              visible: _mapVisible,
              child: Column(
                children: [
                  Align(
                    alignment: alignment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: _MapNodeWidget(
                        subtopic: subtopic,
                        status: status,
                        pulseCtrl: _pulseCtrl,
                        shimmerCtrl: _shimmerCtrl,
                        onTap: isLocked
                            ? null
                            : () => provider.startQuiz(
                                context,
                                subtopic.subtopicId,
                                subtopic.subtopicName,
                                subtopic.allQuestions,
                                quizLength: 7,
                              ),
                      ),
                    ),
                  ),
                  _AnimatedConnector(
                    isLocked: isLocked,
                    shimmerCtrl: _shimmerCtrl,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, QuestProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.96),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CodeQuest',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _StatChip(
                    emoji: '🔥',
                    value: '${provider.streak}',
                    highlight: provider.streak > 0,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(emoji: '💎', value: '${provider.xp}'),
                  const SizedBox(width: 10),
                  _StatChip(
                    emoji: '❤️',
                    value: '${provider.hearts}',
                    highlight: provider.hearts <= 2,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CurrentModuleCard(provider: provider),
        ],
      ),
    );
  }
}

// ── ANIMATED ENTRANCE ───────────────────────────────────────────────────────
// Staggered fade + slide-up for each map row
class _AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final bool visible;

  const _AnimatedEntrance({
    required this.child,
    required this.delay,
    required this.visible,
  });

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_AnimatedEntrance old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ── CHAPTER BANNER ──────────────────────────────────────────────────────────
class _ChapterBanner extends StatelessWidget {
  final String title;
  const _ChapterBanner({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.white10)),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: Colors.white10)),
        ],
      ),
    );
  }
}

// ── ANIMATED CONNECTOR ──────────────────────────────────────────────────────
class _AnimatedConnector extends StatelessWidget {
  final bool isLocked;
  final AnimationController shimmerCtrl;

  const _AnimatedConnector({required this.isLocked, required this.shimmerCtrl});

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      // Dashed locked connector
      return CustomPaint(
        size: const Size(4, 48),
        painter: _DashedLinePainter(),
      );
    }
    // Animated shimmer on unlocked connector
    return AnimatedBuilder(
      animation: shimmerCtrl,
      builder: (context, _) {
        return Container(
          width: 4,
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(
                  0.6 + 0.4 * math.sin(shimmerCtrl.value * math.pi),
                ),
                AppColors.secondary.withOpacity(0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashH = 5.0;
    const gapH = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashH).clamp(0, size.height)),
        paint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── MAP NODE WIDGET ─────────────────────────────────────────────────────────
class _MapNodeWidget extends StatefulWidget {
  final SubtopicFolder subtopic;
  final String status;
  final AnimationController pulseCtrl;
  final AnimationController shimmerCtrl;
  final VoidCallback? onTap;

  const _MapNodeWidget({
    required this.subtopic,
    required this.status,
    required this.pulseCtrl,
    required this.shimmerCtrl,
    this.onTap,
  });

  @override
  State<_MapNodeWidget> createState() => _MapNodeWidgetState();
}

class _MapNodeWidgetState extends State<_MapNodeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _tapScale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _tapCtrl.forward();
  void _onTapUp(_) {
    _tapCtrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _tapCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.status == 'locked';
    final isCompleted = widget.status == 'completed';
    final isActive = !isLocked && !isCompleted;

    IconData icon = isLocked
        ? Icons.lock_outline
        : isCompleted
        ? Icons.star_rounded
        : Icons.play_arrow_rounded;

    Color nodeColor = isLocked
        ? const Color(0xFF1A1D26)
        : isCompleted
        ? const Color(0xFF1A3A2A)
        : AppColors.secondary;

    return Opacity(
      opacity: isLocked ? 0.4 : 1.0,
      child: GestureDetector(
        onTapDown: isLocked ? null : _onTapDown,
        onTapUp: isLocked ? null : _onTapUp,
        onTapCancel: isLocked ? null : _onTapCancel,
        child: ScaleTransition(
          scale: _tapScale,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring — only for the active (playable) node
                  if (isActive)
                    AnimatedBuilder(
                      animation: widget.pulseCtrl,
                      builder: (_, __) {
                        final v = widget.pulseCtrl.value;
                        return Container(
                          width: 75 + 20 * v,
                          height: 75 + 20 * v,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(
                                0.35 * (1 - v),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                  // Second smaller ring for completed nodes
                  if (isCompleted)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.5),
                          width: 2.5,
                        ),
                      ),
                    ),

                  // The node circle
                  AnimatedBuilder(
                    animation: widget.shimmerCtrl,
                    builder: (_, __) {
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: nodeColor,
                          border: Border.all(
                            color: isLocked
                                ? Colors.white10
                                : isCompleted
                                ? Colors.greenAccent.withOpacity(0.6)
                                : AppColors.secondary.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: isLocked
                              ? []
                              : [
                                  BoxShadow(
                                    color: isCompleted
                                        ? Colors.greenAccent.withOpacity(0.25)
                                        : AppColors.secondaryGlow.withOpacity(
                                            0.3 +
                                                0.2 *
                                                    math.sin(
                                                      widget.shimmerCtrl.value *
                                                          math.pi *
                                                          2,
                                                    ),
                                          ),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                        ),
                        child: Icon(
                          icon,
                          color: isLocked
                              ? Colors.white12
                              : isCompleted
                              ? Colors.greenAccent
                              : Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),

                  // Shimmer sweep overlay on locked nodes
                  if (isLocked)
                    AnimatedBuilder(
                      animation: widget.shimmerCtrl,
                      builder: (_, __) {
                        return ClipOval(
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment(
                                    -1 + 2 * widget.shimmerCtrl.value - 0.5,
                                    -1,
                                  ),
                                  end: Alignment(
                                    -1 + 2 * widget.shimmerCtrl.value + 0.5,
                                    1,
                                  ),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                ).createShader(rect);
                              },
                              child: Container(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Label
              SizedBox(
                width: 100,
                child: Text(
                  widget.subtopic.subtopicName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLocked ? Colors.white24 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.3,
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

// ── STAT CHIP ───────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.emoji,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.orange : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CURRENT MODULE CARD ─────────────────────────────────────────────────────
class _CurrentModuleCard extends StatelessWidget {
  final QuestProvider provider;
  const _CurrentModuleCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chapterName = provider.courseMap.isNotEmpty
        ? provider.courseMap.first.chapterName
        : 'Loading Modules...';

    // Count completed subtopics
    int total = 0, done = 0;
    for (final chapter in provider.courseMap) {
      for (final sub in chapter.subtopics) {
        total++;
        if (provider.getSubtopicStatus(sub.subtopicId) == 'completed') done++;
      }
    }
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT MODULE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chapterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    color: AppColors.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done/$total',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── INTERNAL DATA MODEL ─────────────────────────────────────────────────────
class _MapItem {
  final bool isHeader;
  final String? chapterName;
  final SubtopicFolder? subtopic;
  final int indexInChapter;

  _MapItem.header(this.chapterName)
    : isHeader = true,
      subtopic = null,
      indexInChapter = 0;

  _MapItem.node(this.subtopic, this.indexInChapter)
    : isHeader = false,
      chapterName = null;
}
