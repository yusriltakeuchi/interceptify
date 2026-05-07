class Comment {
  final int id;
  final int postId;
  final String name;
  final String email;
  final String body;

  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    postId: json['postId'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    body: json['body'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'name': name,
    'email': email,
    'body': body,
  };

  @override
  String toString() => 'Comment(id: $id, postId: $postId)';
}
