import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int categoryId);
  Future<Category?> getCategoryById(int id);
}