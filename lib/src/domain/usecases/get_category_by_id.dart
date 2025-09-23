import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoryById {
  GetCategoryById(this._repository);

  final CategoryRepository _repository;

  Future<Category?> call(int id) => _repository.getCategoryById(id);
}