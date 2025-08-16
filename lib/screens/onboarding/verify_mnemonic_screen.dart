import 'package:flutter/material.dart';
import 'dart:math';

class VerifyMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const VerifyMnemonicScreen({super.key, required this.mnemonic});

  @override
  State<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends State<VerifyMnemonicScreen>
    with TickerProviderStateMixin {
  late List<String> _mnemonicWords;
  late List<String> _shuffledWords;
  late List<int> _missingIndices;
  late Map<int, String?> _userSelections;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeMnemonic();
    _setupAnimations();
  }

  void _initializeMnemonic() {
    _mnemonicWords = widget.mnemonic.split(' ');
    _missingIndices = _generateRandomIndices();
    _userSelections = {for (int index in _missingIndices) index: null};
    _shuffledWords = List.from(_mnemonicWords)..shuffle();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  List<int> _generateRandomIndices() {
    final random = Random();
    final indices = <int>{};
    while (indices.length < 4) {
      indices.add(random.nextInt(_mnemonicWords.length));
    }
    return indices.toList()..sort();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'Verify Seed Phrase',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInstructionCard(),
          const SizedBox(height: 30),
          Expanded(flex: 3, child: _buildSeedPhraseGrid()),
          const SizedBox(height: 30),
          Expanded(flex: 2, child: _buildWordSelection()),
          const SizedBox(height: 20),
          _buildVerifyButton(),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 15),
          const Text(
            'Verify Your Seed Phrase',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the missing words in positions: ${_missingIndices.map((i) => i + 1).join(', ')}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedPhraseGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _mnemonicWords.length,
        itemBuilder: (context, index) => _buildWordSlot(index),
      ),
    );
  }

  Widget _buildWordSlot(int index) {
    final isMissing = _missingIndices.contains(index);
    final userWord = _userSelections[index];
    final word = isMissing ? userWord : _mnemonicWords[index];

    return GestureDetector(
      onTap: isMissing && userWord != null ? () => _removeWord(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isMissing
              ? (userWord != null
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                    : LinearGradient(
                        colors: [Colors.grey[300]!, Colors.grey[400]!],
                      ))
              : const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
          borderRadius: BorderRadius.circular(12),
          border: isMissing && userWord == null
              ? Border.all(
                  color: Colors.grey[400]!,
                  width: 2,
                  style: BorderStyle.solid,
                )
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMissing && userWord == null
                      ? Colors.grey[600]
                      : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                word ?? '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMissing && userWord == null
                      ? Colors.grey[600]
                      : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Select the correct words:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _shuffledWords
                    .map((word) => _buildWordChip(word))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordChip(String word) {
    final isUsed = _userSelections.values.contains(word);

    return GestureDetector(
      onTap: isUsed ? null : () => _selectWord(word),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUsed
              ? LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!])
              : const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isUsed
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          word,
          style: TextStyle(
            color: isUsed ? Colors.grey[600] : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final isComplete = _userSelections.values.every((word) => word != null);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isComplete
            ? const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              )
            : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: isComplete ? _verifyAndContinue : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  color: isComplete ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Verify & Continue',
                  style: TextStyle(
                    color: isComplete ? Colors.white : Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectWord(String word) {
    final firstEmptyIndex = _missingIndices.firstWhere(
      (index) => _userSelections[index] == null,
      orElse: () => -1,
    );

    if (firstEmptyIndex != -1) {
      setState(() {
        _userSelections[firstEmptyIndex] = word;
      });
    }
  }

  void _removeWord(int index) {
    setState(() {
      _userSelections[index] = null;
    });
  }

  void _verifyAndContinue() {
    bool isCorrect = true;
    for (int index in _missingIndices) {
      if (_userSelections[index] != _mnemonicWords[index]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Incorrect Words'),
        content: const Text('Some words are incorrect. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _userSelections = {
                  for (int index in _missingIndices) index: null,
                };
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
