import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetAllCategories {
  GetAllCategories(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> call() => _repository.getAllCategories();
}