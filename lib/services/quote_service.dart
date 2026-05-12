import 'dart:convert';

import 'package:http/http.dart' as http;

class MotivationalQuote {
  const MotivationalQuote({required this.text, required this.author});

  final String text;
  final String author;

  factory MotivationalQuote.fromJson(Map<String, dynamic> json) {
    return MotivationalQuote(
      text: json['content']?.toString().trim().isNotEmpty == true
          ? json['content'].toString().trim()
          : 'Keep going. The next step matters.',
      author: json['author']?.toString().trim().isNotEmpty == true
          ? json['author'].toString().trim()
          : 'Unknown',
    );
  }
}

class QuoteService {
  Future<MotivationalQuote> fetchQuote() async {
    final response = await http
        .get(Uri.parse('http://api.quotable.io/random'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Unable to load a motivational quote right now.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return MotivationalQuote.fromJson(data);
  }
}
