import '../repositories/category_repository.dart';

class DeleteCategory {
  DeleteCategory(this._repository);

  final CategoryRepository _repository;

  Future<void> call(int categoryId) => _repository.deleteCategory(categoryId);
}