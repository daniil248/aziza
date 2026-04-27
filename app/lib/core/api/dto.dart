import '../i18n/locale_resolver.dart';
import '../money/money.dart';

class CategoryDto {
  CategoryDto({
    required this.id,
    required this.slug,
    required this.sort,
    required this.nameI18n,
    this.imageUrl,
  });

  final String id;
  final String slug;
  final int sort;
  final Map<String, dynamic> nameI18n;
  final String? imageUrl;

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
        id: json['id'] as String,
        slug: json['slug'] as String,
        sort: (json['sort'] as num?)?.toInt() ?? 0,
        nameI18n: Map<String, dynamic>.from(json['name_i18n'] as Map),
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'sort': sort,
        'name_i18n': nameI18n,
        'image_url': imageUrl,
      };

  String name(String locale) => pickI18n(nameI18n, locale);
}

class VariantDto {
  VariantDto({
    required this.label,
    required this.labelI18n,
    required this.weightG,
    required this.price,
  });

  final String label;
  final Map<String, dynamic> labelI18n;
  final int weightG;
  final Money price;

  factory VariantDto.fromJson(Map<String, dynamic> json) => VariantDto(
        label: json['label'] as String,
        labelI18n: json['label_i18n'] is Map
            ? Map<String, dynamic>.from(json['label_i18n'] as Map)
            : <String, dynamic>{},
        weightG: (json['weight_g'] as num).toInt(),
        price: Money((json['price_minor'] as num).toInt()),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'label_i18n': labelI18n,
        'weight_g': weightG,
        'price_minor': price.minor,
      };

  String displayLabel(String locale) {
    final v = pickI18n(labelI18n, locale);
    return v.isNotEmpty ? v : label;
  }
}

class ProductCardDto {
  ProductCardDto({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.nameI18n,
    required this.variants,
    this.mainImageUrl,
  });

  final String id;
  final String slug;
  final String categoryId;
  final Map<String, dynamic> nameI18n;
  final List<VariantDto> variants;
  final String? mainImageUrl;

  factory ProductCardDto.fromJson(Map<String, dynamic> json) => ProductCardDto(
        id: json['id'] as String,
        slug: json['slug'] as String,
        categoryId: json['category_id'] as String,
        nameI18n: Map<String, dynamic>.from(json['name_i18n'] as Map),
        variants: ((json['variants'] as List?) ?? const [])
            .map((e) => VariantDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        mainImageUrl: json['main_image_url'] as String?,
      );

  String name(String locale) => pickI18n(nameI18n, locale);

  Money get fromPrice {
    if (variants.isEmpty) return Money.zero;
    var min = variants.first.price.minor;
    for (final v in variants) {
      if (v.price.minor < min) min = v.price.minor;
    }
    return Money(min);
  }
}

class KbjuDto {
  KbjuDto({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
  });

  final double kcal;
  final double protein;
  final double fat;
  final double carb;

  factory KbjuDto.fromJson(Map<String, dynamic> json) => KbjuDto(
        kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carb: (json['carb'] as num?)?.toDouble() ?? 0,
      );
}

class ProductDetailDto extends ProductCardDto {
  ProductDetailDto({
    required super.id,
    required super.slug,
    required super.categoryId,
    required super.nameI18n,
    required super.variants,
    super.mainImageUrl,
    required this.descriptionI18n,
    required this.ingredientsI18n,
    required this.cookingI18n,
    required this.kbju,
    required this.galleryUrls,
  });

  final Map<String, dynamic> descriptionI18n;
  final Map<String, dynamic> ingredientsI18n;
  final Map<String, dynamic> cookingI18n;
  final KbjuDto kbju;
  final List<String> galleryUrls;

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) => ProductDetailDto(
        id: json['id'] as String,
        slug: json['slug'] as String,
        categoryId: json['category_id'] as String,
        nameI18n: Map<String, dynamic>.from(json['name_i18n'] as Map),
        descriptionI18n: Map<String, dynamic>.from(json['description_i18n'] as Map),
        ingredientsI18n: Map<String, dynamic>.from(json['ingredients_i18n'] as Map),
        cookingI18n: Map<String, dynamic>.from(json['cooking_i18n'] as Map),
        kbju: KbjuDto.fromJson(Map<String, dynamic>.from(json['kbju'] as Map)),
        variants: ((json['variants'] as List?) ?? const [])
            .map((e) => VariantDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        mainImageUrl: json['main_image_url'] as String?,
        galleryUrls: ((json['gallery_urls'] as List?) ?? const []).cast<String>(),
      );

  String description(String locale) => pickI18n(descriptionI18n, locale);
  String ingredients(String locale) => pickI18n(ingredientsI18n, locale);
  String cooking(String locale) => pickI18n(cookingI18n, locale);
}
