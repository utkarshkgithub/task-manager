import 'package:flutter/material.dart';

import '../services/quote_service.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.snapshot, required this.onRetry});

  final AsyncSnapshot<MotivationalQuote> snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      padding: const EdgeInsets.all(20),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting;

    if (isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF888888),
            ),
          ),
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: Color(0xFF888888),
              ),
              const SizedBox(width: 6),
              Text(
                'Daily Motivation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load a quote right now.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try again'),
          ),
        ],
      );
    }

    final quote = snapshot.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_quote_rounded,
              size: 18,
              color: Color(0xFF888888),
            ),
            const SizedBox(width: 6),
            Text(
              'Daily Motivation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF888888),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '"${quote.text}"',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            height: 1.45,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '— ${quote.author}',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
