import 'package:flutter/material.dart';

import 'animated_dice.dart';

// БРОСКИ КУБИКОВ

class DiceScreen extends StatelessWidget {
  const DiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dice = [4, 6, 8, 10, 12, 20];

    return Scaffold(
      appBar: AppBar(title: const Text('Бросить кубики'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: dice.map((sides) {
            return FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiceRollScreen(sides: sides),
                  ),
                );
              },
              child: Text(
                'D$sides',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DiceRollScreen extends StatefulWidget {
  final int sides;

  const DiceRollScreen({super.key, required this.sides});

  @override
  State<DiceRollScreen> createState() => _DiceRollScreenState();
}

class _DiceRollScreenState extends State<DiceRollScreen> {
  void showResult(int value) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DiceResultScreen(sides: widget.sides, result: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Кубик D${widget.sides}'), centerTitle: true),
      body: Center(
        child: GestureDetector(
          child: AnimatedDice(sides: widget.sides, onRolled: showResult),
        ),
      ),
    );
  }
}

class DiceResultScreen extends StatelessWidget {
  final int sides;
  final int result;

  const DiceResultScreen({
    super.key,
    required this.sides,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Результат D$sides'), centerTitle: true),
      body: Center(
        child: Text(
          '$result',
          style: const TextStyle(fontSize: 96, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
