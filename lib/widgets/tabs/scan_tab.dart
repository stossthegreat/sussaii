import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/whisperfire_models.dart';
import '../../services/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  // Inputs
  final TextEditingController _textController = TextEditingController();

  // Presets
  String _selectedRelationship = 'Partner';
  String _selectedTone = 'clinical'; // brutal | soft | clinical
  bool _isAnalyzing = false;

  WhisperfireResponse? _analysis;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: text,
        contentType: 'dm',            // fixed: scan is always dm
        analysisGoal: 'instant_scan', // fixed: one output style
        tone: _selectedTone,
        relationship: _selectedRelationship,
        // NOTE: when you give me ApiService/server, I’ll add preferred_model: "deepseek-v3"
        // without changing any other params.
      );

      if (!mounted) return;
      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // 1) RELATIONSHIP
          _buildRelationshipSelector(),
          const SizedBox(height: 16),

          // 2) MESSAGE
          _buildInputSection(),
          const SizedBox(height: 16),

          // 3) TONE (brutal / soft / clinical)
          _buildToneSelector(),
          const SizedBox(height: 24),

          // SCAN
          GradientButton(
            text: _isAnalyzing ? 'Scanning psychological patterns…' : 'Scan Message',
            isLoading: _isAnalyzing,
            disabled: !hasText,
            icon: _isAnalyzing ? null : const Icon(Icons.psychology, color: Colors.white),
            width: double.infinity,
            height: 56,
            gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]),
            onPressed: _runAnalysis,
          ),
          const SizedBox(height: 24),

          // OUTPUT CARD
          if (_analysis?.scanResult != null) _buildResults(),

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
            const Icon(Icons.radar, color: AppColors.primaryPink, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]).createShader(bounds),
              child: const Text(
                'WHISPERFIRE',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Psychological radar for single messages • instant hidden‑agenda scan',
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

  // ---- MESSAGE ----
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('MESSAGE (1)'),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _textController,
          placeholder: 'Paste their message, bio, or post here…',
          maxLines: 8,
          padding: const EdgeInsets.all(16),
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

  // ---- RESULTS (Shareable Card) ----
  Widget _buildResults() {
    final s = _analysis!.scanResult!;
    return ShareableResultCard(
      title: s.instantRead.headline,
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share coming soon!'), backgroundColor: AppColors.primaryPink),
        );
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreBanner(s.psychologicalScan.redFlagIntensity),
          const SizedBox(height: 16),

          _section('🎯 SALIENT FACTOR', s.instantRead.salientFactor, AppColors.primaryPink),
          const SizedBox(height: 12),

          _section('🎭 HIDDEN AGENDA', s.instantRead.hiddenAgenda, AppColors.primaryPurple),
          const SizedBox(height: 12),

          _section('👑 POWER PLAY', s.instantRead.powerPlay, AppColors.primaryCyan),
          const SizedBox(height: 12),

          _section('🔮 NEXT MOVE', s.instantInsights.nextTacticLikely, AppColors.successGreen),
          const SizedBox(height: 18),

          _rapidBlock(_selectedTone.toUpperCase(), s.rapidResponse.comebackSuggestion),
          const SizedBox(height: 16),

          _viralBlock(s.viralVerdict.sussVerdict, s.viralVerdict.gutValidation),
        ],
      ),
    );
  }

  Widget _scoreBanner(int score) {
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
          Text('🚩 RED FLAG INTENSITY',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text('$score/100', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(isCritical ? 'CRITICAL RISK' : isHigh ? 'HIGH RISK' : 'LOW/MODERATE',
              style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _rapidBlock(String tone, String line) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.pinkPurpleGradient,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: AppColors.primaryPink.withOpacity(0.28), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💬 RAPID RESPONSE ($tone MODE)',
              style: TextStyle(color: AppColors.primaryPink, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Text(line, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
        ],
      ),
    );
  }

  Widget _viralBlock(String verdict, String gut) {
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
          Text('🔥 VIRAL VERDICT',
              style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Text(verdict, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 6),
          Text(gut, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.35)),
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
        Text(content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4));
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
