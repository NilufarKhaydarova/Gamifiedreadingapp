import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart' show AppLocalizationsX;
import '../../../core/theme/app_colors.dart';
import '../../providers/curriculum_provider.dart';
import '../library/add_book_sheet.dart';

class TopicInputScreen extends ConsumerStatefulWidget {
  const TopicInputScreen({super.key});

  @override
  ConsumerState<TopicInputScreen> createState() => _TopicInputScreenState();
}

class _TopicInputScreenState extends ConsumerState<TopicInputScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _isGenerating = false;
  String? _errorText;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _suggestions = [
    ('📚', 'Classic Literature'),
    ('🤖', 'AI Engineering'),
    ('🧠', 'Psychology'),
    ('🏛️', 'Philosophy'),
    ('💰', 'Personal Finance'),
    ('🌿', 'Stoicism'),
    ('🔬', 'Science'),
    ('📈', 'Entrepreneurship'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l = context.l10n;
    final topic = _controller.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorText = l.topicEmpty);
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorText = null;
    });

    try {
      await ref.read(curriculumProvider.notifier).generate(topic);
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorText = context.l10n.commonError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isGenerating
            ? _buildLoadingState()
            : _buildInputState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final l = context.l10n;
    final topic = _controller.text.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🧬', style: TextStyle(fontSize: 56)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l.topicBuilding,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l.topicCurating(topic),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const LinearProgressIndicator(
              backgroundColor: AppColors.primarySurface,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              l.topicMoment,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputState() {
    final l = context.l10n;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                _buildHeader(l),
                const SizedBox(height: 40),
                _buildTextField(l),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 32),
                _buildSuggestions(l),
                const Spacer(),
                _buildGenerateButton(l),
                const SizedBox(height: 16),
                _buildOrDivider(l),
                const SizedBox(height: 16),
                _buildUploadBookButton(l),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('🎓', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appLocalizations.topicTitle,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                height: 1.15,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          appLocalizations.topicSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildTextField(appLocalizations) {
    return TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => _generate(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: appLocalizations.topicHint,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textHint,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textHint, size: 22),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorText: null,
      ),
    );
  }

  Widget _buildSuggestions(appLocalizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.topicPopular,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return _SuggestionChip(
              emoji: s.$1,
              label: s.$2,
              onTap: () {
                _controller.text = s.$2;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                setState(() => _errorText = null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(appLocalizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _generate,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              appLocalizations.topicBuild,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider(appLocalizations) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            appLocalizations.commonOr,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildUploadBookButton(appLocalizations) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: const AddBookSheet(),
            ),
          );
        },
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(appLocalizations.topicUpload),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
