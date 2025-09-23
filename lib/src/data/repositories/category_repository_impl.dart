import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._categoryLocalDataSource);

  final CategoryLocalDataSource _categoryLocalDataSource;

  @override
  Future<List<Category>> getAllCategories() async {
    final models = await _categoryLocalDataSource.getAllCategories();
    return models.cast<Category>();
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    final id = await _categoryLocalDataSource.insertCategory(model);
    return model.copyWithModel(id: id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    return _categoryLocalDataSource.updateCategory(model);
  }

  @override
  Future<void> deleteCategory(int categoryId) async {
    return _categoryLocalDataSource.deleteCategory(categoryId);
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final model = await _categoryLocalDataSource.getCategoryById(id);
    return model;
  }
}