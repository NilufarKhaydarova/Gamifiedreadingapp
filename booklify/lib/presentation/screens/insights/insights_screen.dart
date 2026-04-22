import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart' show AppLocalizationsX;
import '../../../data/models/curriculum.dart';
import '../../../data/services/ai_provider_service.dart';
import '../../../data/services/claude_service.dart';
import '../../../data/services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curriculum_provider.dart';

// ─── AI knowledge-gap provider ────────────────────────────────────────────────

final _knowledgeGapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final curriculum = ref.watch(curriculumProvider).value;
  if (curriculum == null) return {};

  final completedLessons = <String>[];
  final pendingLessons = <String>[];

  for (final level in curriculum.levels) {
    for (final lesson in level.lessons) {
      final label = '${level.bookTitle}: ${lesson.title}';
      if (lesson.isCompleted) {
        completedLessons.add(label);
      } else {
        pendingLessons.add(label);
      }
    }
  }

  if (completedLessons.isEmpty) return {};

  final claude = ClaudeService();
  return claude.analyzeKnowledgeGaps(
    topic: curriculum.topic,
    completedLessons: completedLessons,
    pendingLessons: pendingLessons,
  );
});

// ─── Reading DNA provider ─────────────────────────────────────────────────────

final _readingDnaProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final db = DatabaseService();
  final results = await Future.wait([
    db.getUserReadingProfile(userId),
    db.getReadingAnalytics(userId),
    db.getAllHighlights(userId),
    db.getAllAiInteractions(userId),
  ]);

  final profile = results[0] as Map<String, dynamic>;
  final analytics = results[1] as List<Map<String, dynamic>>;
  final highlights = results[2] as List<Map<String, dynamic>>;
  final interactions = results[3] as List<Map<String, dynamic>>;

  final wpmHistory = analytics
      .where((a) => (a['wpm'] as num? ?? 0) > 0)
      .take(10)
      .map((a) => (a['wpm'] as num).toDouble())
      .toList()
      .reversed
      .toList();

  final books = highlights
      .map((h) => h['book_id'] as String? ?? '')
      .toSet()
      .where((s) => s.isNotEmpty)
      .toList();

  return {
    ...profile,
    'wpmHistory': wpmHistory,
    'recentBooksCount': books.length,
    'totalHighlights': highlights.length,
    'totalInteractions': interactions.length,
    'provider': AiProviderService().providerLabel,
    'providerAvailable': AiProviderService().primaryAvailable != AiProvider.none,
  };
});

// ─── Mastery Radar Painter ────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<double> values; // 5 values, 0.0–1.0
  final List<String> labels;
  final double animValue;   // 0→1 for entrance animation

  const _RadarPainter({
    required this.values,
    required this.labels,
    required this.animValue,
  });

  static const _n = 5;
  static const _rings = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(cx, cy) - 36.0;

    // ── Grid rings ────────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFF6B21A8).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= _rings; ring++) {
      _drawPolygon(canvas, cx, cy, maxR * ring / _rings, gridPaint);
    }

    // ── Axis spokes ───────────────────────────────────────────────────────────
    final spokePaint = Paint()
      ..color = const Color(0xFF6B21A8).withValues(alpha: 0.13)
      ..strokeWidth = 1;

    for (int i = 0; i < _n; i++) {
      final angle = -pi / 2 + 2 * pi * i / _n;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * cos(angle), cy + maxR * sin(angle)),
        spokePaint,
      );
    }

    // ── Filled polygon (animated) ─────────────────────────────────────────────
    final pts = <Offset>[];
    for (int i = 0; i < _n; i++) {
      final angle = -pi / 2 + 2 * pi * i / _n;
      final r = maxR * (values[i] * animValue);
      pts.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < _n; i++) path.lineTo(pts[i].dx, pts[i].dy);
    path.close();

    // fill
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6B21A8).withValues(alpha: 0.28),
            const Color(0xFF4F46E5).withValues(alpha: 0.10),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR)),
    );

    // stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6B21A8).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // value dots
    for (final p in pts) {
      canvas.drawCircle(p, 5,
          Paint()..color = Colors.white);
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = const Color(0xFF6B21A8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // ── Labels ────────────────────────────────────────────────────────────────
    for (int i = 0; i < _n; i++) {
      final angle = -pi / 2 + 2 * pi * i / _n;
      final labelR = maxR + 22;
      final lx = cx + labelR * cos(angle);
      final ly = cy + labelR * sin(angle);
      _drawLabel(canvas, labels[i], Offset(lx, ly));
    }
  }

  void _drawPolygon(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < _n; i++) {
      final angle = -pi / 2 + 2 * pi * i / _n;
      final pt = Offset(cx + r * cos(angle), cy + r * sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 52);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.animValue != animValue || old.values != values;
}

// ─── Animated Mastery Radar Widget ───────────────────────────────────────────

class _MasteryRadar extends StatefulWidget {
  final List<double> values;
  final List<String> labels;

  const _MasteryRadar({required this.values, required this.labels});

  @override
  State<_MasteryRadar> createState() => _MasteryRadarState();
}

class _MasteryRadarState extends State<_MasteryRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 210),
        painter: _RadarPainter(
          values: widget.values,
          labels: widget.labels,
          animValue: _anim.value,
        ),
      ),
    );
  }
}

// ─── Concept Columns ─────────────────────────────────────────────────────────

class _ConceptColumns extends StatelessWidget {
  final List<String> mastered;
  final String masteredLabel;
  final List<String> inProgress;
  final String inProgressLabel;
  final List<String> gaps;
  final String gapsLabel;
  final String unlockHint;
  final String lookingGood;

  const _ConceptColumns({
    required this.mastered,
    required this.masteredLabel,
    required this.inProgress,
    required this.inProgressLabel,
    required this.gaps,
    required this.gapsLabel,
    required this.unlockHint,
    required this.lookingGood,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ConceptSection(
            emoji: '✅',
            title: masteredLabel,
            emptyHint: unlockHint,
            color: const Color(0xFF059669),
            concepts: mastered,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ConceptSection(
            emoji: '📖',
            title: inProgressLabel,
            emptyHint: '–',
            color: const Color(0xFF4F46E5),
            concepts: inProgress,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ConceptSection(
            emoji: '⚠️',
            title: gapsLabel,
            emptyHint: lookingGood,
            color: const Color(0xFFDC2626),
            concepts: gaps,
          ),
        ),
      ],
    );
  }
}

class _ConceptSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String emptyHint;
  final Color color;
  final List<String> concepts;

  const _ConceptSection({
    required this.emoji,
    required this.title,
    required this.emptyHint,
    required this.color,
    required this.concepts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (concepts.isEmpty)
            Text(
              emptyHint,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.5),
                  height: 1.4),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: concepts.take(6).map((c) {
                // Truncate long concept names
                final label = c.length > 18 ? '${c.substring(0, 17)}…' : c;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Combined Knowledge Card ──────────────────────────────────────────────────

class _KnowledgeCard extends StatelessWidget {
  final Curriculum curriculum;
  final Map<String, dynamic> aiData;
  final Map<String, dynamic> dna;

  const _KnowledgeCard({
    required this.curriculum,
    required this.aiData,
    required this.dna,
  });

  @override
  Widget build(BuildContext context) {
    // ── Radar values ─────────────────────────────────────────────────────────
    final totalLessons =
        curriculum.levels.fold(0, (s, l) => s + l.lessons.length);
    final completedLessons = curriculum.levels.fold(
        0, (s, l) => s + l.lessons.where((les) => les.isCompleted).length);

    final progress =
        totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    final avgWpm = (dna['avgWpm'] as num?)?.toDouble() ?? 0;
    final totalHighlights = (dna['totalHighlights'] as num?)?.toInt() ?? 0;
    final totalAiQs = (dna['totalInteractions'] as num?)?.toInt() ?? 0;
    final streak = (dna['streak'] as num?)?.toInt() ?? curriculum.streak;

    // Normalize each axis 0–1
    final speedVal = (avgWpm / 350).clamp(0.0, 1.0);
    final depthVal = totalLessons > 0
        ? (totalHighlights / (completedLessons.clamp(1, 999) * 3.0))
            .clamp(0.0, 1.0)
        : 0.0;
    final aiVal = totalLessons > 0
        ? (totalAiQs / (completedLessons.clamp(1, 999) * 2.0))
            .clamp(0.0, 1.0)
        : 0.0;
    final consistencyVal = (streak / 14.0).clamp(0.0, 1.0);

    // If no real data yet give small non-zero floor so the shape is visible
    final hasActivity = progress > 0 || avgWpm > 0 || totalHighlights > 0;
    final floor = hasActivity ? 0.0 : 0.05;

    final radarValues = [
      (progress + floor).clamp(0.0, 1.0),       // Completion
      (speedVal + floor).clamp(0.0, 1.0),        // Speed
      (depthVal + floor).clamp(0.0, 1.0),        // Depth
      (aiVal + floor).clamp(0.0, 1.0),           // AI
      (consistencyVal + floor).clamp(0.0, 1.0),  // Streak
    ];
    final radarLabels = [
      context.l10n.radarProgress,
      context.l10n.radarSpeed,
      context.l10n.radarDepth,
      context.l10n.radarAi,
      context.l10n.radarConsistency,
    ];

    // ── Concept column data ───────────────────────────────────────────────────
    final mastered =
        (aiData['whatYouKnow'] as List?)?.cast<String>() ?? [];
    final gapMaps =
        (aiData['gaps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final gapConcepts =
        gapMaps.map((g) => g['concept'] as String? ?? '').toList();

    final inProgress = <String>[];
    for (final level in curriculum.levels) {
      for (final lesson in level.lessons) {
        if (lesson.isUnlocked && !lesson.isCompleted) {
          inProgress.add(lesson.title);
          if (inProgress.length >= 6) break;
        }
      }
      if (inProgress.length >= 6) break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.insightsMapLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (hasActivity)
                Text(
                  context.l10n.insightsComplete((progress * 100).round()),
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B21A8),
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            context.l10n.insightsMapSub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),

          // ── Radar chart ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          _MasteryRadar(values: radarValues, labels: radarLabels),

          // Axis legend (colour-coded value pills)
          const SizedBox(height: 8),
          _RadarLegend(values: radarValues, labels: radarLabels),

          // ── Concept columns ───────────────────────────────────────────────
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEF5)),
          const SizedBox(height: 14),

          Text(
            context.l10n.insightsConcepts,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _ConceptColumns(
            mastered: mastered,
            masteredLabel: context.l10n.insightsMastered,
            inProgress: inProgress,
            inProgressLabel: context.l10n.insightsInProgress,
            gaps: gapConcepts,
            gapsLabel: context.l10n.insightsGaps,
            unlockHint: context.l10n.insightsUnlock,
            lookingGood: context.l10n.insightsLookingGood,
          ),
        ],
      ),
    );
  }
}

// ─── Radar legend strip ───────────────────────────────────────────────────────

class _RadarLegend extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _RadarLegend({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6B21A8);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: List.generate(values.length, (i) {
        final pct = (values[i] * 100).round();
        final label = labels[i].replaceAll('\n', ' ');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label $pct%',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6B21A8),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currAsync = ref.watch(curriculumProvider);
    final user = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              userName: user?.displayName ?? 'Learner',
              topic: currAsync.value?.topic,
              onRefresh: () => ref.invalidate(_knowledgeGapProvider),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          currAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (curriculum) => curriculum == null
                ? const SliverFillRemaining(child: _NoTopicState())
                : _InsightsContent(curriculum: curriculum),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;
  final String? topic;
  final VoidCallback onRefresh;

  const _Header(
      {required this.userName, required this.topic, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.insightsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic != null
                      ? context.l10n.insightsTopic(topic!)
                      : context.l10n.insightsChoose,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh analysis',
          ),
        ],
      ),
    );
  }
}

// ─── No topic state ───────────────────────────────────────────────────────────

class _NoTopicState extends StatelessWidget {
  const _NoTopicState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.insightsNoTopicTitle,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.insightsNoTopicBody,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _InsightsContent extends ConsumerWidget {
  final Curriculum curriculum;
  const _InsightsContent({required this.curriculum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gapAsync = ref.watch(_knowledgeGapProvider);
    final user = ref.watch(authUserProvider);
    final dnaAsync = user != null
        ? ref.watch(_readingDnaProvider(user.id))
        : const AsyncValue<Map<String, dynamic>>.data({});

    final totalLessons =
        curriculum.levels.fold(0, (s, l) => s + l.lessons.length);
    final completedLessons = curriculum.levels.fold(
        0,
        (s, l) =>
            s + l.lessons.where((les) => les.isCompleted).length);
    final pct = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Progress strip ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _ProgressStrip(
            topic: curriculum.topic,
            completed: completedLessons,
            total: totalLessons,
            progress: pct,
            totalXP: curriculum.totalXP,
          ),
        ),

        // ── Knowledge Map card (radar + columns) ────────────────────────────
        Builder(builder: (_) {
          final aiData = gapAsync.value ?? {};
          final dna = dnaAsync.value ?? {};
          final loading = gapAsync.isLoading || dnaAsync.isLoading;

          if (loading && aiData.isEmpty && dna.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _KnowledgeLoadingCard(),
            );
          }

          return _KnowledgeCard(
            curriculum: curriculum,
            aiData: aiData,
            dna: dna,
          );
        }),

        const SizedBox(height: 24),

        // ── AI analysis card ────────────────────────────────────────────────
        gapAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (aiData) => aiData.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AnalysisCard(aiData: aiData),
                ),
        ),

        const SizedBox(height: 24),

        // ── Reading DNA panel ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: dnaAsync.when(
            loading: () => const _DnaLoadingCard(),
            error: (_, __) => const SizedBox.shrink(),
            data: (dna) => _ReadingDnaPanel(dna: dna),
          ),
        ),
      ]),
    );
  }
}

// ─── Loading card ─────────────────────────────────────────────────────────────

class _KnowledgeLoadingCard extends StatelessWidget {
  const _KnowledgeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: Color(0xFF6B21A8), strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Building your knowledge map…',
            style: TextStyle(color: Color(0xFF6B21A8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Progress strip ───────────────────────────────────────────────────────────

class _ProgressStrip extends StatelessWidget {
  final String topic;
  final int completed;
  final int total;
  final double progress;
  final int totalXP;

  const _ProgressStrip({
    required this.topic,
    required this.completed,
    required this.total,
    required this.progress,
    required this.totalXP,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        const Color(0xFF6B21A8).withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6B21A8)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $total lessons · ${(progress * 100).round()}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalXP XP',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Analysis card ─────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final Map<String, dynamic> aiData;
  const _AnalysisCard({required this.aiData});

  @override
  Widget build(BuildContext context) {
    final nextStep = aiData['nextStep'] as String? ?? '';
    final thesisRelevance = aiData['thesisRelevance'] as String? ?? '';
    final gaps =
        (aiData['gaps'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gaps.isNotEmpty) ...[
          _SectionLabel('🔍 TOP GAPS TO CLOSE', const Color(0xFFDC2626)),
          const SizedBox(height: 10),
          ...gaps.take(3).map((g) => _GapTile(gap: g)),
          const SizedBox(height: 20),
        ],
        if (thesisRelevance.isNotEmpty) ...[
          _SectionLabel('🎓 THESIS RELEVANCE', const Color(0xFF6B21A8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Text(thesisRelevance,
                style: const TextStyle(
                    fontSize: 13, height: 1.55, color: Color(0xFF1E1B4B))),
          ),
          const SizedBox(height: 20),
        ],
        if (nextStep.isNotEmpty) ...[
          _SectionLabel('🚀 FOCUS NEXT', const Color(0xFF4F46E5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(nextStep,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.5)),
          ),
        ],
      ],
    );
  }
}

// ─── Reading DNA Loading ──────────────────────────────────────────────────────

class _DnaLoadingCard extends StatelessWidget {
  const _DnaLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF6B21A8), strokeWidth: 2),
      ),
    );
  }
}

// ─── Reading DNA Panel ────────────────────────────────────────────────────────

class _ReadingDnaPanel extends StatelessWidget {
  final Map<String, dynamic> dna;
  const _ReadingDnaPanel({required this.dna});

  @override
  Widget build(BuildContext context) {
    final themes =
        (dna['highlightThemes'] as List?)?.cast<String>() ?? [];
    final topics =
        (dna['frequentAiTopics'] as List?)?.cast<String>() ?? [];
    final wpmHistory =
        (dna['wpmHistory'] as List?)?.cast<double>() ?? [];
    final avgWpm = (dna['avgWpm'] as num?)?.toInt() ?? 0;
    final totalHighlights = (dna['totalHighlights'] as num?)?.toInt() ?? 0;
    final totalAiQs = (dna['totalInteractions'] as num?)?.toInt() ?? 0;
    final depth = dna['preferredDepth'] as String? ?? 'unknown';
    final books = (dna['booksEngaged'] as List?)?.cast<String>() ?? [];
    final provider = dna['provider'] as String? ?? 'No AI configured';
    final providerOk = dna['providerAvailable'] as bool? ?? false;
    final booksCount = (dna['recentBooksCount'] as num?)?.toInt() ?? 0;

    final hasData =
        avgWpm > 0 || totalHighlights > 0 || totalAiQs > 0 || themes.isNotEmpty;

    if (!hasData) {
      return _DnaEmptyState(provider: provider, providerOk: providerOk);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.insightsDna,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.insightsDnaSub,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stats row
        Row(
          children: [
            _DnaStat(
              icon: Icons.speed_rounded,
              value: avgWpm > 0 ? '$avgWpm wpm' : '–',
              label: context.l10n.insightsAvgSpeed,
              color: const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 10),
            _DnaStat(
              icon: Icons.bookmark_rounded,
              value: '$totalHighlights',
              label: context.l10n.insightsHighlights,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 10),
            _DnaStat(
              icon: Icons.chat_bubble_outline_rounded,
              value: '$totalAiQs',
              label: context.l10n.insightsAiChats,
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 10),
            _DnaStat(
              icon: Icons.menu_book_rounded,
              value: '$booksCount',
              label: context.l10n.insightsBooks,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // WPM chart
        if (wpmHistory.length >= 2) ...[
          _WpmChart(history: wpmHistory),
          const SizedBox(height: 14),
        ],

        // Depth + provider
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _DepthBadge(depth: depth)),
                  const SizedBox(width: 10),
                  _ProviderBadge(provider: provider, isActive: providerOk),
                ],
              ),
              if (books.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),
                Text(
                  'Books in your profile',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: books
                      .take(4)
                      .map((b) => _MiniChip(
                          label: b,
                          color: const Color(0xFF6B21A8),
                          icon: Icons.menu_book_rounded))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (themes.isNotEmpty) ...[
          _DnaChipRow(
            label: '🔖 WHAT YOU HIGHLIGHT',
            chips: themes,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
        ],

        if (topics.isNotEmpty) ...[
          _DnaChipRow(
            label: '🤖 WHAT YOU ASK THE AI',
            chips: topics,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─── DNA empty state ──────────────────────────────────────────────────────────

class _DnaEmptyState extends StatelessWidget {
  final String provider;
  final bool providerOk;
  const _DnaEmptyState({required this.provider, required this.providerOk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'READING DNA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ProviderBadge(provider: provider, isActive: providerOk),
            ],
          ),
          const SizedBox(height: 20),
          Icon(Icons.auto_awesome_rounded, size: 36, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Your Reading DNA will appear here',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            'Read books, highlight passages, and chat with the AI.\nThe more you read, the more the app adapts to you.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── DNA sub-widgets ──────────────────────────────────────────────────────────

class _DnaStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _DnaStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _WpmChart extends StatelessWidget {
  final List<double> history;
  const _WpmChart({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  size: 14, color: Color(0xFF4F46E5)),
              const SizedBox(width: 6),
              Text(
                'Reading Speed (last ${history.length} sessions)',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1B4B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _WpmChartPainter(history: history),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Session 1',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400])),
              Text('Latest',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }
}

class _WpmChartPainter extends CustomPainter {
  final List<double> history;
  const _WpmChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final minV = history.reduce(min);
    final maxV = history.reduce(max);
    final range = (maxV - minV).clamp(1.0, double.infinity);

    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final x = i / (history.length - 1) * size.width;
      final y = size.height -
          ((history[i] - minV) / range * (size.height - 12) + 6);
      points.add(Offset(x, y));
    }

    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4F46E5).withValues(alpha: 0.25),
            const Color(0xFF4F46E5).withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF4F46E5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      canvas.drawCircle(
          p,
          3,
          Paint()
            ..color = const Color(0xFF4F46E5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    final last = points.last;
    final tp = TextPainter(
      text: TextSpan(
        text: '${history.last.round()}',
        style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(last.dx - tp.width / 2, last.dy - 16));
  }

  @override
  bool shouldRepaint(_WpmChartPainter old) => old.history != history;
}

class _DepthBadge extends StatelessWidget {
  final String depth;
  const _DepthBadge({required this.depth});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (depth) {
      'deep' =>
        ('Deep Reader', const Color(0xFF6B21A8), Icons.psychology_rounded),
      'light' =>
        ('Light Reader', const Color(0xFF059669), Icons.flutter_dash),
      _ => ('Moderate Reader', const Color(0xFF4F46E5),
          Icons.auto_stories_rounded),
    };

    final desc = switch (depth) {
      'deep' => 'You explore every detail',
      'light' => 'You read at a swift pace',
      _ => 'Balanced depth and speed',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(desc,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  final String provider;
  final bool isActive;
  const _ProviderBadge({required this.provider, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final icon =
        isActive ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(provider,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _DnaChipRow extends StatelessWidget {
  final String label;
  final List<String> chips;
  final Color color;
  const _DnaChipRow(
      {required this.label, required this.chips, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .take(8)
                .map((c) => _MiniChip(label: c, color: color))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _MiniChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: icon != null ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2),
    );
  }
}

class _GapTile extends StatelessWidget {
  final Map<String, dynamic> gap;
  const _GapTile({required this.gap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 14, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap['concept'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B)),
                ),
                if ((gap['why'] as String?) != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    gap['why'] as String,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
