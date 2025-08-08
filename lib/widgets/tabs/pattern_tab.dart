import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/whisperfire_models.dart';
import '../../services/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';

class PatternTab extends StatefulWidget {
  const PatternTab({super.key});

  @override
  State<PatternTab> createState() => _PatternTabState();
}

class _PatternTabState extends State<PatternTab> {
  // Inputs
  final List<TextEditingController> _messageControllers = [TextEditingController()];
  final TextEditingController _nameController = TextEditingController();

  // Presets
  String _selectedRelationship = 'Partner';
  String _selectedTone = 'clinical'; // brutal | soft | clinical
  bool _isAnalyzing = false;

  WhisperfireResponse? _analysis;

  @override
  void initState() {
    super.initState();
    _messageControllers[0].addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _messageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- ANALYZE ACTION ----
  Future<void> _runPatternAnalysis() async {
    final messages = _messageControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (messages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 messages (up to 10).')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      // Join with newline (backend splits for pattern_profiling)
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: messages.join('\n'),
        contentType: 'dm',
        analysisGoal: 'pattern_profiling',
        tone: _selectedTone,
        relationship: _selectedRelationship,
        personName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        // NOTE: when you send me ApiService/server, I’ll wire `preferred_model: deepseek-v3` end-to-end.
        // For now we keep the call signature identical to your current service.
      );

      if (!mounted) return;
      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pattern analysis failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---- UI HELPERS ----
  void _addMessage() {
    if (_messageControllers.length >= 10) return;
    final c = TextEditingController();
    c.addListener(() => setState(() {}));
    setState(() => _messageControllers.add(c));
  }

  int get _validMessageCount =>
      _messageControllers.where((c) => c.text.trim().isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // 1) RELATIONSHIP (single control)
          _buildRelationshipSelector(),
          const SizedBox(height: 16),

          // Optional person label
          _buildPersonNameField(),
          const SizedBox(height: 24),

          // 2) MESSAGES (2–10)
          _buildMessageStack(),
          const SizedBox(height: 24),

          // 3) TONE (brutal/soft/clinical)
          _buildToneSelector(),
          const SizedBox(height: 24),

          // Analyze
          _buildAnalyzeButton(),
          const SizedBox(height: 24),

          // Output
          if (_analysis?.patternResult != null) _buildPatternResults(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ---- HEADER ----
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, color: AppColors.primaryPurple, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]).createShader(bounds),
              child: const Text(
                'PATTERN.AI',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Behavioral profiler for 2–10 messages • detects cycles, risk, and counter‑moves',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGray400, fontSize: 13),
        ),
      ],
    );
  }

  // ---- RELATIONSHIP ----
  Widget _buildRelationshipSelector() {
    final relationships = [
      {'id': 'Partner', 'label': '💕 Partner'},
      {'id': 'Ex', 'label': '💔 Ex'},
      {'id': 'Date', 'label': '💘 Date'},
      {'id': 'Family', 'label': '👨‍👩‍👧‍👦 Family'},
      {'id': 'Friend', 'label': '👥 Friend'},
      {'id': 'Coworker', 'label': '💼 Coworker'},
      {'id': 'Roommate', 'label': '🏡 Roommate'},
      {'id': 'Stranger', 'label': '❓ Stranger'},
      {'id': 'Boss', 'label': '🏢 Boss'},
      {'id': 'Acquaintance', 'label': '🤝 Acquaintance'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('RELATIONSHIP'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(color: AppColors.borderGray600),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationship,
              isExpanded: true,
              dropdownColor: AppColors.backgroundGray800,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: relationships
                  .map((rel) => DropdownMenuItem<String>(
                        value: rel['id']!,
                        child: Text(rel['label']!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRelationship = v!),
            ),
          ),
        ),
      ],
    );
  }

  // ---- PERSON NAME (optional) ----
  Widget _buildPersonNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('NAME THIS PERSON (OPTIONAL)'),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _nameController,
          placeholder: 'e.g., “Toxic Ex”, “Confusing Coworker”',
          padding: const EdgeInsets.all(12),
        ),
      ],
    );
  }

  // ---- MESSAGES (2–10) ----
  Widget _buildMessageStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('MESSAGES ($_validMessageCount/10)'),
        const SizedBox(height: 10),
        ..._messageControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Stack(
              children: [
                CustomTextField(
                  controller: controller,
                  placeholder: 'Message ${index + 1}...',
                  maxLines: 5,
                  padding: const EdgeInsets.all(12),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray800.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.textGray500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (_messageControllers.length < 10)
          GestureDetector(
            onTap: _addMessage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderGray600, width: 2),
                borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('+', style: TextStyle(color: AppColors.textGray400, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('Add Message',
                      style: TextStyle(color: AppColors.textGray400, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- TONE (brutal/soft/clinical) ----
  Widget _buildToneSelector() {
    final tones = [
      {'id': 'brutal', 'label': '🔥 Brutal', 'desc': 'Maximum exposure'},
      {'id': 'soft', 'label': '💚 Soft', 'desc': 'Gentle & validating'},
      {'id': 'clinical', 'label': '🧪 Clinical', 'desc': 'Forensic & neutral'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TONE'),
        const SizedBox(height: 10),
        Row(
          children: tones.map((tone) {
            final selected = _selectedTone == tone['id'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomOutlinedButton(
                  text: '',
                  isSelected: selected,
                  selectedColor: AppColors.primaryPurple,
                  onPressed: () => setState(() => _selectedTone = tone['id']!),
                  child: Column(
                    children: [
                      Text(
                        tone['label']!,
                        style: TextStyle(
                          color: selected ? AppColors.primaryPurple : AppColors.textGray400,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tone['desc']!,
                        style: TextStyle(
                          color: (selected ? AppColors.primaryPurple : AppColors.textGray400).withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---- ANALYZE BUTTON ----
  Widget _buildAnalyzeButton() {
    return GradientButton(
      text: _isAnalyzing ? 'Profiling behavioral pattern…' : 'Analyze Communication Pattern',
      isLoading: _isAnalyzing,
      disabled: _validMessageCount < 2,
      icon: _isAnalyzing ? null : const Icon(Icons.psychology, color: Colors.white),
      width: double.infinity,
      height: 56,
      gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]),
      onPressed: _runPatternAnalysis,
    );
  }

  // ---- RESULTS (Shareable Card) ----
  Widget _buildPatternResults() {
    final p = _analysis!.patternResult!;

    return ShareableResultCard(
      title: p.behavioralProfile.headline,
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share coming soon!'),
            backgroundColor: AppColors.primaryPink,
          ),
        );
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score banner
          _buildPatternScoreSection(p.patternAnalysis.patternSeverityScore),
          const SizedBox(height: 18),

          _section('🎭 MANIPULATOR ARCHETYPE', p.behavioralProfile.manipulatorArchetype, AppColors.primaryPink),
          const SizedBox(height: 12),

          _section('🔄 DOMINANT PATTERN', p.behavioralProfile.dominantPattern, AppColors.primaryPurple),
          const SizedBox(height: 12),

          _section('🔮 FUTURE BEHAVIOR PREDICTION', p.riskAssessment.futureBehaviorPrediction, AppColors.primaryCyan),
          const SizedBox(height: 12),

          _section('🛡️ STRATEGIC RECOMMENDATIONS', p.strategicRecommendations.boundaryEnforcementStrategy, AppColors.successGreen),
          const SizedBox(height: 18),

          _viralBlock(p.viralInsights.sussVerdict, p.viralInsights.lifeSavingInsight),
        ],
      ),
    );
  }

  Widget _buildPatternScoreSection(int score) {
    final isHigh = score >= 60;
    final isCritical = score >= 80;

    final gradient = isCritical
        ? LinearGradient(colors: [AppColors.dangerRed, AppColors.dangerRed.withOpacity(0.8)])
        : isHigh
            ? LinearGradient(colors: [AppColors.warningOrange, AppColors.warningOrange.withOpacity(0.85)])
            : LinearGradient(colors: [AppColors.successGreen, AppColors.successGreen.withOpacity(0.85)]);

    final borderColor = isCritical
        ? AppColors.dangerRed.withOpacity(0.3)
        : isHigh
            ? AppColors.warningOrange.withOpacity(0.3)
            : AppColors.successGreen.withOpacity(0.3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Text('🧩 PATTERN SEVERITY', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text('$score/100', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(isCritical ? 'CRITICAL PATTERN' : isHigh ? 'HIGH RISK' : 'LOW/MODERATE',
              style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _viralBlock(String verdict, String lifesaver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.blueCyanGradient,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.28), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 VIRAL INSIGHTS',
              style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Text(verdict, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 6),
          Text(lifesaver, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }

  Widget _section(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      );
}

/* =========================
   Reusable ShareableResultCard
   ========================= */

class ShareableResultCard extends StatelessWidget {
  final String title; // Headline
  final Widget body; // Inner content
  final VoidCallback onShare; // Share action
  final EdgeInsetsGeometry? padding;

  const ShareableResultCard({
    super.key,
    required this.title,
    required this.body,
    required this.onShare,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray800,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: AppColors.borderGray600, width: 1),
      ),
      child: Column(
        children: [
          // Header (title + Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ShareButton(onTap: onShare),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: AppColors.borderGray600.withOpacity(0.6)),

          // Body
          Padding(padding: padding ?? const EdgeInsets.all(16), child: body),

          // Footer brand
          const _BrandingFooter(),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryPink.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryPink, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.share, color: AppColors.primaryPink, size: 16),
            SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                color: AppColors.primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandingFooter extends StatelessWidget {
  const _BrandingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGray600, width: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.visibility, color: AppColors.primaryPink, size: 16),
          SizedBox(width: 8),
          Text(
            'MySnitch AI',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
