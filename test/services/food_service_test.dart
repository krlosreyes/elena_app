import 'package:elena_app/src/features/nutrition/application/food_service.dart';
import 'package:elena_app/src/features/nutrition/data/repositories/food_repository.dart';
import 'package:elena_app/src/features/nutrition/data/repositories/food_suggestions_repository.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/food_model.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/food_suggestion.dart';
import 'package:elena_app/src/features/profile/data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'food_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FoodRepository>(),
  MockSpec<FoodSuggestionsRepository>(),
  MockSpec<UserRepository>(),
])
void main() {
  late MockFoodRepository foodRepository;
  late MockFoodSuggestionsRepository suggestionsRepository;
  late MockUserRepository userRepository;
  late FoodService service;

  setUp(() {
    foodRepository = MockFoodRepository();
    suggestionsRepository = MockFoodSuggestionsRepository();
    userRepository = MockUserRepository();
    service =
        FoodService(foodRepository, suggestionsRepository, userRepository);
  });

  group('FoodService', () {
    test('getFoodsByCategory delega en el repositorio', () async {
      final sampleFood = _food(id: 'salmon', category: 'Proteína 🐟');
      when(foodRepository.getFoodsByCategory('Proteína 🐟'))
          .thenAnswer((_) async => [sampleFood]);

      final result = await service.getFoodsByCategory('Proteína 🐟');

      expect(result, hasLength(1));
      expect(result.first.id, 'salmon');
      verify(foodRepository.getFoodsByCategory('Proteína 🐟')).called(1);
      verifyNoMoreInteractions(foodRepository);
    });

    test('searchFood usa el repositorio y devuelve coincidencia', () async {
      final sampleFood = _food(id: 'avena');
      when(foodRepository.getFoodMetadata('avena'))
          .thenAnswer((_) async => sampleFood);

      final result = await service.searchFood('avena');

      expect(result, isNotNull);
      expect(result!.name, sampleFood.name);
      verify(foodRepository.getFoodMetadata('avena')).called(1);
    });

    test('generatePersonalizedPool guarda el pool personalizado ordenado',
        () async {
      final user = UserModel.empty().copyWith(
        uid: 'user-123',
        email: 'demo@elena.test',
        displayName: 'Demo',
        gender: Gender.female,
      );

      final highProtein = _food(
        id: 'steak',
        name: 'Steak',
        category: 'Proteína 🐟',
        protein: 32,
        fat: 12,
        netCarbs: 2,
        calories: 260,
        searchTags: ['carne'],
      );

      final highCarb = _food(
        id: 'pasta',
        name: 'Pasta',
        category: 'Carbos',
        protein: 10,
        fat: 2,
        netCarbs: 60,
        calories: 350,
        searchTags: ['trigo'],
      );

      when(userRepository.getUser('user-123')).thenAnswer((_) async => user);
      when(foodRepository.getAllFoods())
          .thenAnswer((_) async => [highProtein, highCarb]);
      when(suggestionsRepository.savePersonalizedPool(any, any))
          .thenAnswer((_) async => Future.value());

      await service.generatePersonalizedPool('user-123', ['steak']);

      verify(
        suggestionsRepository.savePersonalizedPool(
          'user-123',
          argThat(predicate<List<FoodSuggestion>>((pool) {
            expect(pool, hasLength(2));
            expect(pool.first.foodId, 'steak');
            expect(pool.first.preferencesMatch, isTrue);
            expect(pool.first.macros.protein, 32);
            expect(pool.first.category, FoodCategory.principal);
            return true;
          })),
        ),
      ).called(1);
    });

    test('generatePersonalizedPool lanza error si el usuario no existe',
        () async {
      when(userRepository.getUser('ghost')).thenAnswer((_) async => null);

      expect(
        () => service.generatePersonalizedPool('ghost', const []),
        throwsException,
      );
    });
  });
}

FoodModel _food({
  required String id,
  String name = 'Demo Food',
  String category = 'Proteína 🐟',
  List<String> searchTags = const ['demo'],
  double protein = 20,
  double fat = 5,
  double netCarbs = 5,
  double calories = 200,
}) {
  return FoodModel(
    id: id,
    name: name,
    category: category,
    searchTags: searchTags,
    protein: protein,
    fat: fat,
    netCarbs: netCarbs,
    calories: calories,
    imrScore: 8,
    tip: 'demo',
    impact: 'general',
    level: 1,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}
