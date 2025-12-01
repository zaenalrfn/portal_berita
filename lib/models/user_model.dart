class UserModel {
  final int id;
  final String name;
  final String email;
  final int totalNews;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.totalNews,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    final name = json['name']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';

    final dynamic tn = json['total_news'] ?? json['totalNews'] ?? json['total'] ?? 0;
    final totalNews = tn is int ? tn : int.tryParse(tn.toString()) ?? 0;

    return UserModel(
      id: id,
      name: name,
      email: email,
      totalNews: totalNews,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'total_news': totalNews,
      };
}
