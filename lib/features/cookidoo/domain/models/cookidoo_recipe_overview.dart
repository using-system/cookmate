class CookidooRecipeOverview {
  const CookidooRecipeOverview({
    required this.id,
    required this.title,
    required this.rating,
    required this.numberOfRatings,
    required this.totalTime,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final double rating;
  final int numberOfRatings;
  final int totalTime;
  final String imageUrl;

  factory CookidooRecipeOverview.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ?? '';
    return CookidooRecipeOverview(
      id: json['id'] as String,
      title: json['title'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numberOfRatings: json['numberOfRatings'] as int? ?? 0,
      totalTime: json['totalTime'] as int? ?? 0,
      imageUrl: image.replaceAll(
        '{transformation}',
        't_web_shared_recipe_221x240',
      ),
    );
  }
}
