import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../home/home_screen.dart';

class VerifyMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const VerifyMnemonicScreen({super.key, required this.mnemonic});

  @override
  State<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends State<VerifyMnemonicScreen> {
  late List<String> _words;
  late List<int> _selectedIndices;
  late Map<int, List<String>> _questionOptions; // Her soru için seçenekler
  final Map<int, String> _userAnswers = {};
  bool _isVerificationComplete = false;
  bool _hasError = false;
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    _words = widget.mnemonic.split(' ');
    _generateRandomIndices();
    _generateQuestionOptions();
  }

  void _generateRandomIndices() {
    final random = Random();
    final indices = <int>[];

    // 3 rastgele index seç (0-11 arası)
    while (indices.length < 3) {
      final index = random.nextInt(_words.length);
      if (!indices.contains(index)) {
        indices.add(index);
      }
    }

    indices.sort();
    _selectedIndices = indices;
  }

  void _generateQuestionOptions() {
    _questionOptions = {};
    final random = Random();

    for (int i = 0; i < _selectedIndices.length; i++) {
      final correctWord = _words[_selectedIndices[i]];
      final options = <String>[correctWord];

      // Diğer kelimelerden rastgele 3 tane seç
      while (options.length < 4) {
        final randomWord = _words[random.nextInt(_words.length)];
        if (!options.contains(randomWord)) {
          options.add(randomWord);
        }
      }

      // Seçenekleri karıştır
      options.shuffle();
      _questionOptions[i] = options;
    }
  }

  void _onWordSelected(int questionIndex, String word) {
    setState(() {
      _userAnswers[questionIndex] = word;
      _hasError = false;

      // Tüm sorular cevaplandı mı kontrol et
      _isVerificationComplete = _userAnswers.length == 3;
    });
  }

  void _verifyAnswers() {
    _attemptCount++;
    bool allCorrect = true;

    for (int i = 0; i < _selectedIndices.length; i++) {
      final correctWord = _words[_selectedIndices[i]];
      final userAnswer = _userAnswers[i];

      if (correctWord != userAnswer) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      // Doğrulama başarılı - ana ekrana git
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _hasError = true;
        _userAnswers.clear();
        _isVerificationComplete = false;
        // Sadece doğrulama butonuna tıkladıktan sonra yeni kelimeler seç
        _generateRandomIndices();
        _generateQuestionOptions();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yanlış kelimeler seçildi. $_attemptCount. deneme - Yeni kelimeler sorulacak.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Bu metod artık kullanılmıyor - seçenekler önceden oluşturuluyor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Phrase Doğrulama'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve açıklama
              Text(
                'Seed Phrase\'inizi Doğrulayın',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Güvenlik için lütfen aşağıdaki pozisyonlardaki kelimeleri seçin:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Doğrulama soruları
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedIndices.length,
                  itemBuilder: (context, index) {
                    final wordIndex = _selectedIndices[index];
                    final options = _questionOptions[index]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${wordIndex + 1}. kelime nedir?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Seçenekler
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((option) {
                                final isSelected =
                                    _userAnswers[index] == option;
                                final hasError = _hasError && isSelected;

                                return ChoiceChip(
                                  label: Text(option),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _onWordSelected(index, option);
                                    }
                                  },
                                  selectedColor: hasError
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.errorContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: hasError
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer
                                        : isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Doğrula butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerificationComplete ? _verifyAnswers : null,
                  child: const Text('Doğrula ve Devam Et'),
                ),
              ),

              const SizedBox(height: 16),

              // Geri dön butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Geri Dön'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
