import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../models/whisperfire_models.dart';
import '../../services/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/gradient_button.dart';
import '../common/outlined_button.dart';
import '../common/result_card.dart';

class PatternTab extends StatefulWidget {
  const PatternTab({super.key});

  @override
  State<PatternTab> createState() => _PatternTabState();
}

class _PatternTabState extends State<PatternTab> {
  final List<TextEditingController> _messageControllers = [TextEditingController()];
  final TextEditingController _nameController = TextEditingController();
  String _selectedRelationship = 'Partner';
  String _selectedOutputMode = 'Intel'; // NEW: From backend ARCHETYPES
  String _selectedTone = 'clinical'; // NEW: Matches backend exactly
  bool _isAnalyzing = false;
  WhisperfireResponse? _analysis;

  @override
  void initState() {
    super.initState();
    _messageControllers[0].addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _messageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _runPatternAnalysis() async {
    final messages = _messageControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (messages.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final result = await ApiService.analyzeMessageWhisperfire(
        inputText: messages.join('\n'),
        contentType: 'dm',
        analysisGoal: 'pattern_profiling',
        tone: _selectedTone,
        relationship: _selectedRelationship,
        personName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _analysis = result;
          _isAnalyzing = false;
        });
      }
    } catch (error) {
      print('❌ Pattern analysis failed: $error');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pattern analysis failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMessage() {
    if (_messageControllers.length < 5) {
      setState(() {
        final newController = TextEditingController();
        newController.addListener(() {
          setState(() {});
        });
        _messageControllers.add(newController);
      });
    }
  }

  int get _validMessageCount {
    return _messageControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          
          // 🔥 RELATIONSHIP CONTEXT - Matches backend ARCHETYPES exactly
          _buildRelationshipSelector(),
          const SizedBox(height: 24),
          
          // 👤 PERSON NAME - NEW: From backend prompt (personName parameter)
          _buildPersonNameField(),
          const SizedBox(height: 24),
          
          // 🎭 OUTPUT MODE - NEW: From backend ARCHETYPES (Intel/Narrative/Roast)
          _buildOutputModeSelector(),
          const SizedBox(height: 24),
          
          // 🎨 TONE SELECTOR - Matches backend getToneInstructions exactly
          _buildToneSelector(),
          const SizedBox(height: 24),
          
          // 📝 MESSAGE STACK
          _buildMessageStack(),
          const SizedBox(height: 24),
          
          _buildAnalyzeButton(),
          const SizedBox(height: 24),
          
          if (_analysis != null && _analysis!.patternResult != null) _buildPatternResults(),
          
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
              Icons.psychology,
              color: AppColors.primaryPurple,
              size: 32,
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.primaryPink],
              ).createShader(bounds),
              child: const Text(
                'PATTERN.AI',
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
          'High-stakes behavioral profiler detecting manipulation loops',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // 🔥 RELATIONSHIP CONTEXT - Exactly matches backend ARCHETYPES
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

  // 👤 PERSON NAME - NEW: From backend personName parameter
  Widget _buildPersonNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAME THIS PERSON (OPTIONAL)',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _nameController,
          placeholder: 'e.g., "Toxic Ex", "Confusing Coworker"',
          padding: const EdgeInsets.all(12),
        ),
      ],
    );
  }

  // 🎭 OUTPUT MODE - NEW: From backend ARCHETYPES (Intel/Narrative/Roast)
  Widget _buildOutputModeSelector() {
    final outputModes = [
      {'id': 'Intel', 'label': '🎯 Intel', 'desc': 'Tactical threat brief'},
      {'id': 'Narrative', 'label': '📖 Narrative', 'desc': 'Story-driven breakdown'},
      {'id': 'Roast', 'label': '🔥 Roast', 'desc': 'Savage but truthful'},
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

  // 🎨 TONE SELECTOR - Exactly matches backend getToneInstructions
  Widget _buildToneSelector() {
    final tones = [
      {'id': 'brutal', 'label': '🔥 Brutal', 'desc': 'Maximum exposure'},
      {'id': 'serious', 'label': '⚖️ Serious', 'desc': 'Firm & credible'},
      {'id': 'clinical', 'label': '🧪 Clinical', 'desc': 'Forensic'},
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

  Widget _buildMessageStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MESSAGES ($_validMessageCount/5)',
          style: TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        
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
                      color: AppColors.backgroundGray800.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.textGray500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        
        if (_messageControllers.length < 5)
          GestureDetector(
            onTap: _addMessage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.borderGray600,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+',
                    style: TextStyle(
                      color: AppColors.textGray400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Message',
                    style: TextStyle(
                      color: AppColors.textGray400,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return GradientButton(
      text: _isAnalyzing ? 'Profiling behavioral patterns...' : 'Analyze Communication Pattern',
      isLoading: _isAnalyzing,
      disabled: _validMessageCount < 2,
      icon: _isAnalyzing ? null : const Icon(Icons.psychology, color: Colors.white),
      width: double.infinity,
      height: 56,
      gradient: const LinearGradient(
        colors: [AppColors.primaryPurple, AppColors.primaryPink],
      ),
      onPressed: _runPatternAnalysis,
    );
  }

  Widget _buildPatternResults() {
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
                    _analysis!.patternResult!.behavioralProfile.headline,
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
          
          // Pattern Severity Score
          _buildPatternScoreSection(),
          const SizedBox(height: 24),
          
          // Key Pattern Insights
          _buildPremiumPatternSection(
            '🎭 MANIPULATOR ARCHETYPE',
            _analysis!.patternResult!.behavioralProfile.manipulatorArchetype,
            AppColors.primaryPink,
          ),
          const SizedBox(height: 16),
          
          _buildPremiumPatternSection(
            '🔄 DOMINANT PATTERN',
            _analysis!.patternResult!.behavioralProfile.dominantPattern,
            AppColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          
          _buildPremiumPatternSection(
            '🔮 FUTURE BEHAVIOR PREDICTION',
            _analysis!.patternResult!.riskAssessment.futureBehaviorPrediction,
            AppColors.primaryCyan,
          ),
          const SizedBox(height: 16),
          
          _buildPremiumPatternSection(
            '🛡️ STRATEGIC RECOMMENDATIONS',
            _analysis!.patternResult!.strategicRecommendations.boundaryEnforcementStrategy,
            AppColors.successGreen,
          ),
          const SizedBox(height: 20),
          
          // Viral Insights
          _buildViralInsightsSection(),
          const SizedBox(height: 24),
          
          _buildPremiumBranding(),
        ],
      ),
    );
  }

  Widget _buildPatternScoreSection() {
    final score = _analysis!.patternResult!.patternAnalysis.patternSeverityScore;
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
            '🧩 PATTERN SEVERITY SCORE',
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
            isCritical ? 'CRITICAL PATTERN' : isHighRisk ? 'HIGH RISK' : 'SAFE PATTERN',
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

  Widget _buildPremiumPatternSection(String title, String content, Color color) {
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

  Widget _buildViralInsightsSection() {
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
                '🔥 VIRAL INSIGHTS',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'LIFE-SAVING',
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
            _analysis!.patternResult!.viralInsights.sussVerdict,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysis!.patternResult!.viralInsights.lifeSavingInsight,
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
            Icons.psychology,
            color: AppColors.primaryPink,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'PATTERN.AI',
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
