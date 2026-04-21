import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookidooRecipeOverview.fromJson', () {
    test('parses complete data correctly', () {
      final json = {
        'id': 'r123',
        'title': 'Chicken Curry',
        'rating': 4.5,
        'numberOfRatings': 120,
        'totalTime': 3600,
        'image': 'https://example.com/{transformation}/image.jpg',
      };

      final overview = CookidooRecipeOverview.fromJson(json);

      expect(overview.id, 'r123');
      expect(overview.title, 'Chicken Curry');
      expect(overview.rating, 4.5);
      expect(overview.numberOfRatings, 120);
      expect(overview.totalTime, 3600);
      expect(
        overview.imageUrl,
        'https://example.com/t_web_shared_recipe_221x240/image.jpg',
      );
    });

    test('applies image transformation replacing {transformation} placeholder', () {
      final json = {
        'id': 'r1',
        'title': 'Soup',
        'image': 'https://cdn.example.com/{transformation}/photo.jpg',
      };

      final overview = CookidooRecipeOverview.fromJson(json);

      expect(overview.imageUrl,
          'https://cdn.example.com/t_web_shared_recipe_221x240/photo.jpg');
    });

    test('defaults missing optional fields to zero/empty', () {
      final json = {
        'id': 'r456',
        'title': 'Soup',
      };

      final overview = CookidooRecipeOverview.fromJson(json);

      expect(overview.rating, 0.0);
      expect(overview.numberOfRatings, 0);
      expect(overview.totalTime, 0);
      expect(overview.imageUrl, '');
    });

    test('handles null image gracefully', () {
      final json = {
        'id': 'r789',
        'title': 'Stew',
        'image': null,
      };

      final overview = CookidooRecipeOverview.fromJson(json);

      expect(overview.imageUrl, '');
    });

    test('converts integer rating to double', () {
      final json = {
        'id': 'r1',
        'title': 'Cake',
        'rating': 5,
      };

      final overview = CookidooRecipeOverview.fromJson(json);

      expect(overview.rating, 5.0);
      expect(overview.rating, isA<double>());
    });
  });
}
