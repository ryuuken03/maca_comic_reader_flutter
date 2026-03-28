class GenreModel {
  final int id;
  final String name;
  final String? description;

  GenreModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    final innerData = json['data'] as Map<String, dynamic>;
    return GenreModel(
      id: json['id'],
      name: innerData['name'] ?? '',
      description: innerData['description'],
    );
  }
}
