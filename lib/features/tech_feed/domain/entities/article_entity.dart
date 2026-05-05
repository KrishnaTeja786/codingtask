import 'package:equatable/equatable.dart';

class ArticleEntity extends Equatable {
  const ArticleEntity({
    required this.id,
    required this.title,
    required this.url,
    required this.author,
    required this.score,
    required this.commentCount,
    required this.createdAt,
    this.topic,
  });

  final int id;
  final String title;
  final String? url;
  final String? author;
  final int score;
  final int commentCount;
  final DateTime createdAt;
  final String? topic;

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        author,
        score,
        commentCount,
        createdAt,
        topic,
      ];
}
