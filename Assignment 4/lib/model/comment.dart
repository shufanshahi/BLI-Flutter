class Comment {
  final int id;
  final String by;
  final List<int> kids;
  final int parent;
  final String text;
  final int time;
  final String type;

  Comment({
    required this.id,
    required this.by,
    required this.kids,
    required this.parent,
    required this.text,
    required this.time,
    required this.type,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      by: json['by'] ?? '',
      kids: List<int>.from(json['kids'] ?? []),
      parent: json['parent'] ?? 0,
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time * 1000);
}