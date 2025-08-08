import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/whisperfire_models.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';

class ComebacksTab extends StatefulWidget {
  const ComebacksTab({super.key});

  @override
  State<ComebacksTab> createState() => _ComebacksTabState();
}

class _ComebacksTabState extends State<ComebacksTab> {
  final TextEditingController _textController = TextEditingController();

  // Presets
  String _selectedRelationship = 'Partner';
  String _selectedTone = 'clinical'; // brutal | soft | clinical
  bool _isGenerating = false;

  // Result
  String _comeback = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Temporary mapping so we work with current backend tone names.
  // When you give me the backend, I'll switch it to pass-through (brutal/soft/clinical).
  String _mapToneForBackend(String t) {
    switch (t) {
      case 'brutal':
        return 'savage';   // hard-hitting
      case 'soft':
        return 'playful';  // friendly / disarming
      case 'clinical':
      default:
        return 'mature';   // calm / grounded
    }
  }

  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _comeback = '';
    });

    try {
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: text,
        contentType: 'dm',
        analysisGoal: 'comeback_generation',
        tone: _mapToneForBackend(_selectedTone),
        relationship: _selectedRelationship,
        // NOTE: when you give me ApiService/server, I’ll wire preferred_model: "deepseek-v3"
      );

      if (!mounted) return;
      setState(() {
        _comeback = result.comebackResult?.primaryComeback ?? 'No comeback generated';
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _comeback = 'Failed to generate comeback. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comeback generation failed: $e'), backgroundColor: Colors.red),
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

          // 1) Relationship
          _buildRelationshipSelector(),
          const SizedBox(height: 16),

          // 2) Message
          _buildInputField(),
          const SizedBox(height: 16),

          // 3) Tone presets (brutal / soft / clinical)
          _buildToneSelector(),
          const SizedBox(height: 24),

          // Generate
          GradientButton(
            text: _isGenerating ? 'Crafting comeback…' : 'Generate Comeback',
            isLoading: _isGenerating,
            disabled: !hasText,
            icon: _isGenerating ? null : const Icon(Icons.flash_on, color: Colors.white),
            width: double.infinity,
            height: 56,
            gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]),
            onPressed: _generate,
          ),
          const SizedBox(height: 24),

          // Shareable card
          if (_comeback.isNotEmpty) _buildResultCard(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- UI PARTS ---

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: AppColors.primaryPink, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]).createShader(bounds),
              child: const Text(
                'COMEBACKS',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'One-line power response — screenshot-ready',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGray400, fontSize: 13),
        ),
      ],
    );
  }

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

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('MESSAGE'),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _textController,
          placeholder: 'Paste their message (or gist) here…',
          maxLines: 6,
          padding: const EdgeInsets.all(16),
        ),
      ],
    );
  }

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
                  selectedColor: AppColors.primaryPink,
                  onPressed: () => setState(() => _selectedTone = tone['id']!),
                  child: Column(
                    children: [
                      Text(
                        tone['label']!,
                        style: TextStyle(
                          color: selected ? AppColors.primaryPink : AppColors.textGray400,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tone['desc']!,
                        style: TextStyle(
                          color: (selected ? AppColors.primaryPink : AppColors.textGray400).withOpacity(0.75),
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

  Widget _buildResultCard() {
    return ShareableResultCard(
      title: '💬 Your Comeback (${_selectedTone.toUpperCase()})',
      onShare: _share,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _comeback,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: '📋 Copy',
                  bg: AppColors.primaryPink.withOpacity(0.18),
                  fg: AppColors.primaryPink,
                  onTap: _copy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: '💾 Save to Vault',
                  bg: AppColors.primaryPurple.withOpacity(0.18),
                  fg: AppColors.primaryPurple,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _comeback));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Comeback copied!'), backgroundColor: AppColors.primaryPink),
    );
  }

  void _save() {
    // Hook your vault later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Saved to vault!'), backgroundColor: AppColors.primaryPurple),
    );
  }

  void _share() {
    // Hook your share handler later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon!'), backgroundColor: AppColors.primaryPink),
    );
  }

  Widget _actionButton({required String label, required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimation,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppConstants.mediumRadius)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(color: AppColors.textGray400, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4),
    );
  }
}

/* =========================
   Reusable ShareableResultCard
   ========================= */

class ShareableResultCard extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback onShare;
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
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.3, fontWeight: FontWeight.w800),
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
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderGray600, width: 0.6))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.visibility, color: AppColors.primaryPink, size: 16),
          SizedBox(width: 8),
          Text(
            'MySnitch AI',
            style: TextStyle(color: AppColors.primaryPink, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
