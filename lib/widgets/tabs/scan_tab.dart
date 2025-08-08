import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/whisperfire_models.dart';
import '../../services/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';
import '../common/result_card.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final TextEditingController _textController = TextEditingController();
  String _selectedCategory = 'dm';
  String _selectedTone = 'brutal';
  String _selectedRelationship = 'Partner';
  String _selectedAnalysisGoal = 'instant_scan';
  String _selectedOutputMode = 'Intel'; // NEW: Missing from your current UI
  bool _isAnalyzing = false;
  WhisperfireResponse? _analysis;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: _textController.text.trim(),
        contentType: _selectedCategory,
        analysisGoal: _selectedAnalysisGoal,
        tone: _selectedTone,
        relationship: _selectedRelationship,
      );

      if (mounted) {
        setState(() {
          _analysis = result;
          _isAnalyzing = false;
        });
      }
    } catch (error) {
      print('❌ Scan analysis failed: $error');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          
          // 🔥 RELATIONSHIP CONTEXT - Matches backend exactly
          _buildRelationshipSelector(),
          const SizedBox(height: 24),
          
          _buildInputSection(),
          const SizedBox(height: 24),
          
          // 📱 CONTENT TYPE - Matches backend exactly
          _buildContentTypeSelector(),
          const SizedBox(height: 20),
          
          // ⚡ ANALYSIS GOAL - Matches backend exactly
          _buildAnalysisGoalSelector(),
          const SizedBox(height: 20),
          
          // 🎭 OUTPUT MODE - NEW: From backend prompts
          _buildOutputModeSelector(),
          const SizedBox(height: 20),
          
          // 🎨 TONE STYLE - Matches backend exactly
          _buildToneSelector(),
          const SizedBox(height: 24),
          
          _buildScanButton(),
          const SizedBox(height: 24),
          
          if (_analysis != null && _analysis!.scanResult != null) _buildResults(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.radar,
              color: AppColors.primaryPink,
              size: 32,
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'WHISPERFIRE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Psychological radar that scans messages in seconds',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // 🔥 RELATIONSHIP CONTEXT - Exactly matches backend RELATIONSHIP_CONTEXTS
  Widget _buildRelationshipSelector() {
    final relationships = [
      {'id': 'Partner', 'label': '💕 Partner', 'desc': 'Romantic relationships'},
      {'id': 'Ex', 'label': '💔 Ex', 'desc': 'Former partners'},
      {'id': 'Date', 'label': '💘 Date', 'desc': 'Dating situations'},
      {'id': 'Family', 'label': '👨‍👩‍👧‍👦 Family', 'desc': 'Family dynamics'},
      {'id': 'Friend', 'label': '👥 Friend', 'desc': 'Friendships'},
      {'id': 'Coworker', 'label': '💼 Coworker', 'desc': 'Work relationships'},
      {'id': 'Roommate', 'label': '🏡 Roommate', 'desc': 'Living situations'},
      {'id': 'Stranger', 'label': '❓ Stranger', 'desc': 'Unknown people'},
      {'id': 'Boss', 'label': '💼 Boss', 'desc': 'Authority figures'},
      {'id': 'Acquaintance', 'label': '🤝 Acquaintance', 'desc': 'Casual connections'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATIONSHIP CONTEXT',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              items: relationships.map((rel) {
                return DropdownMenuItem<String>(
                  value: rel['id']!,
                  child: Row(
                    children: [
                      Text(rel['label']!),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rel['desc']!,
                          style: TextStyle(
                            color: AppColors.textGray400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRelationship = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return CustomTextField(
      controller: _textController,
      placeholder: 'Paste their message, bio, or story here...',
      maxLines: 8,
      padding: const EdgeInsets.all(16),
    );
  }

  // 📱 CONTENT TYPE - Exactly matches backend getContentTypeContext
  Widget _buildContentTypeSelector() {
    final contentTypes = [
      {'id': 'dm', 'label': '💬 DM', 'desc': 'Private messages'},
      {'id': 'bio', 'label': '📝 Bio', 'desc': 'Profile bios'},
      {'id': 'story', 'label': '📱 Story', 'desc': 'Social stories'},
      {'id': 'post', 'label': '📢 Post', 'desc': 'Social posts'},
      {'id': 'email', 'label': '📧 Email', 'desc': 'Email messages'},
      {'id': 'text', 'label': '💬 Text', 'desc': 'SMS messages'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENT TYPE',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: contentTypes.map((type) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              child: CustomOutlinedButton(
                text: type['label']!,
                isSelected: _selectedCategory == type['id'],
                selectedColor: AppColors.primaryPink,
                onPressed: () {
                  setState(() {
                    _selectedCategory = type['id']!;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ⚡ ANALYSIS GOAL - Matches backend exactly
  Widget _buildAnalysisGoalSelector() {
    final goals = [
      {'id': 'instant_scan', 'label': '⚡ Instant Scan', 'desc': 'Quick psychological radar'},
      {'id': 'comeback_generation', 'label': '🗡️ Comeback Generation', 'desc': 'Viral weapon creation'},
      {'id': 'pattern_profiling', 'label': '🧠 Pattern Profiling', 'desc': 'Deep behavioral analysis'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYSIS GOAL',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray800,
            borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
            border: Border.all(color: AppColors.borderGray600),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAnalysisGoal,
              isExpanded: true,
              dropdownColor: AppColors.backgroundGray800,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: goals.map((goal) {
                return DropdownMenuItem<String>(
                  value: goal['id']!,
                  child: Row(
                    children: [
                      Text(goal['label']!),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal['desc']!,
                          style: TextStyle(
                            color: AppColors.textGray400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAnalysisGoal = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // 🎭 OUTPUT MODE - NEW: From backend getOutputModeFlavor
  Widget _buildOutputModeSelector() {
    final outputModes = [
      {'id': 'Intel', 'label': '🎯 Intel', 'desc': 'Tactical, factual'},
      {'id': 'Narrative', 'label': '📖 Narrative', 'desc': 'Story-driven'},
      {'id': 'Roast', 'label': '🔥 Roast', 'desc': 'Savage but truthful'},
      {'id': 'Therapeutic', 'label': '💚 Therapeutic', 'desc': 'Healing & validating'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUTPUT MODE',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: outputModes.map((mode) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomOutlinedButton(
                  text: '',
                  isSelected: _selectedOutputMode == mode['id'],
                  selectedColor: AppColors.primaryCyan,
                  onPressed: () {
                    setState(() {
                      _selectedOutputMode = mode['id']!;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        mode['label']!,
                        style: TextStyle(
                          color: _selectedOutputMode == mode['id']
                              ? AppColors.primaryCyan
                              : AppColors.textGray400,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode['desc']!,
                        style: TextStyle(
                          color: (_selectedOutputMode == mode['id']
                                  ? AppColors.primaryCyan
                                  : AppColors.textGray400)
                              .withOpacity(0.7),
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

  // 🎨 TONE STYLE - Exactly matches backend getToneInstructions
  Widget _buildToneSelector() {
    final tones = [
      {'id': 'brutal', 'label': '🔥 Brutal', 'desc': 'No filter'},
      {'id': 'serious', 'label': '⚖️ Serious', 'desc': 'Firm & clear'},
      {'id': 'clinical', 'label': '🧪 Clinical', 'desc': 'Neutral'},
      {'id': 'compassionate', 'label': '💚 Compassionate', 'desc': 'Gentle'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYSIS TONE',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: tones.map((tone) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomOutlinedButton(
                  text: '',
                  isSelected: _selectedTone == tone['id'],
                  selectedColor: AppColors.primaryPurple,
                  onPressed: () {
                    setState(() {
                      _selectedTone = tone['id']!;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        tone['label']!,
                        style: TextStyle(
                          color: _selectedTone == tone['id']
                              ? AppColors.primaryPurple
                              : AppColors.textGray400,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tone['desc']!,
                        style: TextStyle(
                          color: (_selectedTone == tone['id']
                                  ? AppColors.primaryPurple
                                  : AppColors.textGray400)
                              .withOpacity(0.7),
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

  Widget _buildScanButton() {
    final hasText = _textController.text.trim().isNotEmpty;
    
    return GradientButton(
      text: _isAnalyzing ? 'Scanning psychological patterns...' : 'Scan Message',
      isLoading: _isAnalyzing,
      disabled: !hasText,
      icon: _isAnalyzing ? null : const Icon(Icons.psychology, color: Colors.white),
      width: double.infinity,
      height: 56,
      onPressed: _runAnalysis,
    );
  }

  Widget _buildResults() {
    return ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderGray600,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _analysis!.scanResult!.instantRead.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                        backgroundColor: AppColors.primaryPink,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryPink,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share,
                          color: AppColors.primaryPink,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Red Flag Score
          _buildPremiumScoreSection(),
          const SizedBox(height: 24),
          
          // Key Insights
          _buildPremiumSection(
            '🎯 PRIMARY MOTIVE',
            _analysis!.scanResult!.instantRead.salientFactor,
            AppColors.primaryPink,
          ),
          const SizedBox(height: 16),
          
          _buildPremiumSection(
            '🧠 HIDDEN SUBTEXT',
            _analysis!.scanResult!.instantInsights.whatTheyreNotSaying,
            AppColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          
          _buildPremiumSection(
            '🔮 NEXT MOVE PREDICTION',
            _analysis!.scanResult!.instantInsights.nextTacticLikely,
            AppColors.primaryCyan,
          ),
          const SizedBox(height: 16),
          
          // Comeback Section
          _buildPremiumComebackSection(),
          const SizedBox(height: 20),
          
          // Viral Verdict
          _buildPremiumViralVerdictSection(),
          const SizedBox(height: 24),
          
          _buildPremiumBranding(),
        ],
      ),
    );
  }

  Widget _buildPremiumScoreSection() {
    final score = _analysis!.scanResult!.psychologicalScan.redFlagIntensity;
    final isHighRisk = score >= 60;
    final isCritical = score >= 80;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCritical 
            ? LinearGradient(colors: [AppColors.dangerRed, AppColors.dangerRed.withOpacity(0.8)])
            : isHighRisk
                ? LinearGradient(colors: [AppColors.warningOrange, AppColors.warningOrange.withOpacity(0.8)])
                : LinearGradient(colors: [AppColors.successGreen, AppColors.successGreen.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(
          color: isCritical 
              ? AppColors.dangerRed.withOpacity(0.3)
              : isHighRisk
                  ? AppColors.warningOrange.withOpacity(0.3)
                  : AppColors.successGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            '🚩 RED FLAG INTENSITY',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score/100',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCritical ? 'CRITICAL RISK' : isHighRisk ? 'HIGH RISK' : 'SAFE ZONE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumComebackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.pinkPurpleGradient,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(
          color: AppColors.primaryPink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💬 RAPID RESPONSE (${_selectedTone.toUpperCase()} MODE)',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _analysis!.scanResult!.rapidResponse.comebackSuggestion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumViralVerdictSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.blueCyanGradient,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🔥 VIRAL VERDICT',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'SCREENSHOT WORTHY',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysis!.scanResult!.viralVerdict.sussVerdict,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysis!.scanResult!.viralVerdict.gutValidation,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBranding() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderGray600,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility,
            color: AppColors.primaryPink,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'MySnitch AI',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
