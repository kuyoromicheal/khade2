import '../models/models.dart';

/// Category chips — matcha green Material icons, "All" first.
class KhadeCategories {
  KhadeCategories._();

  static const all = CategoryModel(
    id: 0,
    slug: 'all',
    label: 'All',
    emoji: '✨',
    filter: '',
    iconName: 'view-grid-outline',
  );

  static const List<CategoryModel> home = [
    all,
    CategoryModel(id: 1, slug: 'hair', label: 'Hair', emoji: '💇', filter: 'hair', iconName: 'hair-dryer-outline'),
    CategoryModel(id: 2, slug: 'nails', label: 'Nails', emoji: '💅', filter: 'nail', iconName: 'nail'),
    CategoryModel(id: 3, slug: 'makeup', label: 'Makeup', emoji: '💄', filter: 'makeup', iconName: 'lipstick'),
    CategoryModel(id: 4, slug: 'brows_lashes', label: 'Brows & Lashes', emoji: '👁️', filter: 'lash', iconName: 'eye-outline'),
    CategoryModel(id: 5, slug: 'barbing', label: 'Barbing', emoji: '✂️', filter: 'barb', iconName: 'content-cut'),
    CategoryModel(id: 6, slug: 'spa', label: 'Spa', emoji: '🧖', filter: 'spa', iconName: 'leaf-maple-outline'),
    CategoryModel(id: 7, slug: 'massage', label: 'Massage', emoji: '💆', filter: 'massage', iconName: 'hand-heart-outline'),
    CategoryModel(id: 8, slug: 'skincare', label: 'Skincare', emoji: '🧴', filter: 'skin', iconName: 'face-woman-outline'),
    CategoryModel(id: 9, slug: 'braids', label: 'Braids & Locs', emoji: '🪡', filter: 'braid', iconName: 'wave'),
    CategoryModel(id: 10, slug: 'dental', label: 'Dental', emoji: '🦷', filter: 'dental', iconName: 'tooth-outline'),
    CategoryModel(id: 11, slug: 'facials', label: 'Facials', emoji: '🧖‍♂️', filter: 'facial', iconName: 'face-woman-shimmer-outline'),
    CategoryModel(id: 12, slug: 'pedicure', label: 'Pedicure', emoji: '🦶', filter: 'pedi', iconName: 'foot-print'),
    CategoryModel(id: 13, slug: 'waxing', label: 'Waxing', emoji: '🎀', filter: 'wax', iconName: 'bandage-outline'),
    CategoryModel(id: 14, slug: 'tattoo', label: 'Tattoo', emoji: '🖋️', filter: 'tattoo', iconName: 'needle'),
  ];

  /// Two-row home preview (Fresha-style).
  static List<CategoryModel> get homePreview => home.take(10).toList();
}
