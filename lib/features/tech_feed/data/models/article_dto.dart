import '../../domain/entities/article_entity.dart';

class HnItemDto {
  const HnItemDto({
    required this.id,
    required this.title,
    required this.url,
    required this.author,
    required this.score,
    required this.descendants,
    required this.time,
  });

  final int id;
  final String title;
  final String? url;
  final String? author;
  final int score;
  final int descendants;
  final int time; // unix seconds

  factory HnItemDto.fromJson(Map<String, dynamic> json) {
    return HnItemDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '(untitled)',
      url: json['url'] as String?,
      author: json['by'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      descendants: (json['descendants'] as num?)?.toInt() ?? 0,
      time: (json['time'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'by': author,
        'score': score,
        'descendants': descendants,
        'time': time,
      };

  ArticleEntity toEntity({String? topic}) => ArticleEntity(
        id: id,
        title: title,
        url: url,
        author: author,
        score: score,
        commentCount: descendants,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          time * 1000,
          isUtc: true,
        ),
        topic: topic,
      );
}
