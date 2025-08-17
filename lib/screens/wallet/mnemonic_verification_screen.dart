import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'biometric_setup_screen.dart';
import '../../core/services/wallet_unlock_service.dart';

class MnemonicVerificationScreen extends StatefulWidget {
  final String mnemonic;
  final String userId;
  final String password;

  const MnemonicVerificationScreen({
    super.key,
    required this.mnemonic,
    required this.userId,
    required this.password,
  });

  @override
  State<MnemonicVerificationScreen> createState() =>
      _MnemonicVerificationScreenState();
}

class _MnemonicVerificationScreenState extends State<MnemonicVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _mnemonicWords = [];
  List<String> _shuffledWords = [];
  List<String> _selectedWords = [];
  List<int> _verificationIndices = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _setupVerification();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupVerification() {
    _mnemonicWords = widget.mnemonic.split(' ');

    // Select 4 random words to verify (ensure we have enough words)
    final totalWords = _mnemonicWords.length;
    if (totalWords < 4) {
      // Fallback for short mnemonics
      _verificationIndices = List.generate(totalWords, (index) => index);
    } else {
      // Generate random indices
      final random = Random();
      final indices = <int>{};

      // Keep generating until we have 4 unique indices
      while (indices.length < 4) {
        indices.add(random.nextInt(totalWords));
      }

      _verificationIndices = indices.toList()..sort();
    }

    // Create shuffled list of words to choose from
    final wordsToVerify = _verificationIndices
        .map((i) => _mnemonicWords[i])
        .toList();

    // Add some random distractor words from BIP39 wordlist
    final distractorWords = [
      'abandon',
      'ability',
      'about',
      'above',
      'absent',
      'absorb',
      'abstract',
      'absurd',
      'abuse',
      'access',
      'accident',
      'account',
      'accuse',
      'achieve',
      'acid',
      'acoustic',
      'acquire',
      'across',
    ];

    // Remove any distractor words that are already in our verification words
    final filteredDistractors = distractorWords
        .where((word) => !wordsToVerify.contains(word))
        .take(6)
        .toList();

    _shuffledWords = [...wordsToVerify, ...filteredDistractors]..shuffle();

    _selectedWords = List.filled(_verificationIndices.length, '');
  }

  void _selectWord(String word, int position) {
    setState(() {
      _selectedWords[position] = word;
      _errorMessage = null;
    });
  }

  void _removeWord(int position) {
    setState(() {
      _selectedWords[position] = '';
      _errorMessage = null;
    });
  }

  bool get _isVerificationComplete {
    return _selectedWords.every((word) => word.isNotEmpty);
  }

  bool get _isVerificationCorrect {
    for (int i = 0; i < _verificationIndices.length; i++) {
      if (_selectedWords[i] != _mnemonicWords[_verificationIndices[i]]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _verifyAndContinue() async {
    if (!_isVerificationComplete) {
      setState(() {
        _errorMessage = 'Please select all words';
      });
      return;
    }

    if (!_isVerificationCorrect) {
      setState(() {
        _errorMessage = 'Incorrect words selected. Please try again.';
        _selectedWords = List.filled(_verificationIndices.length, '');
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Unlock the wallet to get session
      final unlockResult = await WalletUnlockService.unlockWallet(
        userId: widget.userId,
        password: widget.password,
      );

      if (unlockResult.success &&
          unlockResult.walletSession != null &&
          mounted) {
        // Navigate to biometric setup screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen(
              walletSession: unlockResult.walletSession!,
              password: widget.password,
            ),
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to unlock wallet';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkOnSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verify Recovery Phrase',
          style: TextStyle(
            color: AppColors.darkOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verify Your Recovery Phrase',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Select the correct words in the right order to verify your recovery phrase.',
                                style: TextStyle(
                                  color: AppColors.darkOnSurface.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Verification slots
                        const Text(
                          'Select the missing words:',
                          style: TextStyle(
                            color: AppColors.darkOnSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_verificationIndices.length, (
                            index,
                          ) {
                            final wordIndex = _verificationIndices[index];
                            final selectedWord = _selectedWords[index];

                            return SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 72) / 2,
                              child: GestureDetector(
                                onTap: selectedWord.isNotEmpty
                                    ? () => _removeWord(index)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: selectedWord.isNotEmpty
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedWord.isNotEmpty
                                          ? AppColors.primary
                                          : AppColors.darkOnSurface.withOpacity(
                                              0.3,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${wordIndex + 1}.',
                                        style: TextStyle(
                                          color: AppColors.darkOnSurface
                                              .withOpacity(0.6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedWord.isNotEmpty
                                              ? selectedWord
                                              : '___',
                                          style: TextStyle(
                                            color: selectedWord.isNotEmpty
                                                ? AppColors.primary
                                                : AppColors.darkOnSurface
                                                      .withOpacity(0.4),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (selectedWord.isNotEmpty)
                                        Icon(
                                          Icons.close,
                                          color: AppColors.darkOnSurface
                                              .withOpacity(0.6),
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 32),

                        // Word options
                        const Text(
                          'Choose from these words:',
                          style: TextStyle(
                            color: AppColors.darkOnSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _shuffledWords.map((word) {
                            final isSelected = _selectedWords.contains(word);

                            return GestureDetector(
                              onTap: isSelected
                                  ? null
                                  : () {
                                      final emptyIndex = _selectedWords
                                          .indexWhere((w) => w.isEmpty);
                                      if (emptyIndex != -1) {
                                        _selectWord(word, emptyIndex);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.darkOnSurface.withOpacity(0.1)
                                      : AppColors.darkSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.darkOnSurface.withOpacity(
                                            0.3,
                                          )
                                        : AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  word,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.darkOnSurface.withOpacity(
                                            0.5,
                                          )
                                        : AppColors.darkOnSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerificationComplete && !_isLoading
                        ? _verifyAndContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
