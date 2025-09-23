import '../entities/category.dart';
import '../repositories/category_repository.dart';

class InsertCategory {
  InsertCategory(this._repository);

  final CategoryRepository _repository;

  Future<Category> call(Category category) => _repository.insertCategory(category);
}