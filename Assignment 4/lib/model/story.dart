class Story {
  final int id;
  final String title;
  final String? url;
  final String? text;
  final int score;
  final String by;
  final int time;
  final List<int> kids;
  final String type;

  Story({
    required this.id,
    required this.title,
    this.url,
    this.text,
    required this.score,
    required this.by,
    required this.time,
    required this.kids,
    required this.type,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'],
      text: json['text'],
      score: json['score'] ?? 0,
      by: json['by'] ?? '',
      time: json['time'] ?? 0,
      kids: List<int>.from(json['kids'] ?? []),
      type: json['type'] ?? '',
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time * 1000);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'text': text,
      'score': score,
      'by': by,
      'time': time,
      'kids': kids,
      'type': type,
    };
  }
}