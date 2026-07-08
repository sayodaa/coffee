import 'dart:convert';

import 'package:coffee_app/new_data/business_report.dart';
import 'package:flutter/material.dart';

import 'bi_theme.dart';

/// "Ask Business AI" card.
///
/// Deliberately does **not** call any AI API directly. It only builds a
/// compact prompt (the summarized [BusinessReport], never raw sales rows)
/// and hands it to [onAsk] — the host page wires that up to whatever the
/// app's existing AI assistant entry point is (e.g. navigating to
/// `AiAssistantPage` the same way `ReportsPage._triggerAiAnalysis` already
/// does). This keeps the widget reusable even if the AI integration changes.
class BiAiAssistantCard extends StatefulWidget {
  final BusinessReport report;
  final void Function(String prompt) onAsk;

  const BiAiAssistantCard({
    super.key,
    required this.report,
    required this.onAsk,
  });

  static const List<String> exampleQuestions = [
    'Should I reorder my best selling product?',
    'Which product earns the most profit?',
    'Which product is losing money?',
    'Which ingredient costs the most?',
    'What should I restock?',
    'Why are profits dropping?',
    'Which category is growing?',
  ];

  /// Builds the full prompt sent to the AI assistant: the user's question
  /// plus a compact JSON snapshot of the analytics — never the raw dataset.
  static String buildPrompt(String question, BusinessReport report) {
    final summary = jsonEncode(report.toCompactJson());
    return 'You are a business analyst for a coffee shop. Answer the '
        'question using ONLY the summarized analytics JSON below — it '
        'already reflects the full dataset, aggregated.\n\n'
        'Question: $question\n\n'
        'Business analytics summary (JSON):\n$summary';
  }

  @override
  State<BiAiAssistantCard> createState() => _BiAiAssistantCardState();
}

class _BiAiAssistantCardState extends State<BiAiAssistantCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? presetQuestion]) {
    final question = presetQuestion ?? _controller.text.trim();
    if (question.isEmpty) return;
    widget.onAsk(BiAiAssistantCard.buildPrompt(question, widget.report));
  }

  @override
  Widget build(BuildContext context) {
    return BiGlassCard(
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BiColors.caramel.withOpacity(0.9),
                      BiColors.caramel.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: BiColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ask Business AI',
                  style: TextStyle(
                    color: BiColors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ask anything about your sales, profit, or inventory — the AI '
            'only sees a summarized analytics snapshot, never raw records.',
            style: TextStyle(
              color: BiColors.white.withOpacity(0.65),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in BiAiAssistantCard.exampleQuestions)
                _SuggestionChip(label: q, onTap: () => _submit(q)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: BiColors.white, fontSize: 13.5),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Type your own question…',
                    hintStyle:
                        TextStyle(color: BiColors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _submit(),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: BiColors.caramel,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: BiColors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: BiColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
