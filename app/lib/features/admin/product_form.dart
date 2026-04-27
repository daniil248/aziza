import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/dto.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';

/// Modal form for creating / editing a product.
/// Returns true if anything was saved (so caller can refresh list).
class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({super.key, this.initial, required this.categories});

  final ProductDetailDto? initial;
  final List<CategoryDto> categories;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slug;
  late String _categoryId;
  bool _active = true;
  int _sort = 0;

  late final Map<String, TextEditingController> _name;
  late final Map<String, TextEditingController> _desc;
  late final Map<String, TextEditingController> _ing;
  late final Map<String, TextEditingController> _cook;

  late final TextEditingController _kcal, _protein, _fat, _carb;

  late List<_VariantRow> _variants;

  String? _imageUrl; // server-relative path or absolute
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _slug = TextEditingController(text: p?.slug ?? '');
    _categoryId = p?.categoryId ?? widget.categories.first.id;
    _active = true;
    _sort = 0;

    _name = _i18n(p?.nameI18n);
    _desc = _i18n(p?.descriptionI18n);
    _ing = _i18n(p?.ingredientsI18n);
    _cook = _i18n(p?.cookingI18n);

    _kcal = TextEditingController(text: (p?.kbju.kcal ?? 0).toStringAsFixed(0));
    _protein = TextEditingController(text: (p?.kbju.protein ?? 0).toStringAsFixed(1));
    _fat = TextEditingController(text: (p?.kbju.fat ?? 0).toStringAsFixed(1));
    _carb = TextEditingController(text: (p?.kbju.carb ?? 0).toStringAsFixed(1));

    _variants = (p?.variants ?? const <VariantDto>[]).map(_VariantRow.fromDto).toList();
    if (_variants.isEmpty) _variants.add(_VariantRow.empty());

    _imageUrl = p?.mainImageUrl;
  }

  Map<String, TextEditingController> _i18n(Map<String, dynamic>? src) {
    return {
      'ru': TextEditingController(text: src?['ru']?.toString() ?? ''),
      'kk': TextEditingController(text: src?['kk']?.toString() ?? ''),
      'en': TextEditingController(text: src?['en']?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    _slug.dispose();
    for (final m in [_name, _desc, _ing, _cook]) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _kcal.dispose();
    _protein.dispose();
    _fat.dispose();
    _carb.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      final url = await ref.read(adminApiProvider).uploadImage(
            bytes: bytes,
            filename: picked.name,
            mimeType: mime,
          );
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Map<String, dynamic> _payload() => {
        'slug': _slug.text.trim(),
        'category_id': _categoryId,
        'name_i18n': {for (final e in _name.entries) e.key: e.value.text.trim()},
        'description_i18n': {for (final e in _desc.entries) e.key: e.value.text.trim()},
        'ingredients_i18n': {for (final e in _ing.entries) e.key: e.value.text.trim()},
        'cooking_i18n': {for (final e in _cook.entries) e.key: e.value.text.trim()},
        'kbju': {
          'kcal': double.tryParse(_kcal.text) ?? 0,
          'protein': double.tryParse(_protein.text) ?? 0,
          'fat': double.tryParse(_fat.text) ?? 0,
          'carb': double.tryParse(_carb.text) ?? 0,
        },
        'variants': _variants
            .where((v) => v.label.text.trim().isNotEmpty)
            .map((v) => v.toJson())
            .toList(),
        'main_image_url': _imageUrl,
        'is_active': _active,
        'sort': _sort,
      };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(adminApiProvider);
      if (widget.initial == null) {
        await api.createProduct(_payload());
      } else {
        await api.updateProduct(widget.initial!.id, _payload());
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.initial?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text(widget.initial?.name('ru') ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminApiProvider).deleteProduct(id);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final api = ref.read(adminApiProvider);
    final imageAbs = api.absoluteImageUrl(_imageUrl);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Редактирование' : 'Новый товар'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 22),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ImagePicker(
              imageUrl: imageAbs,
              uploading: _uploading,
              onPick: _pickAndUpload,
              onClear: () => setState(() => _imageUrl = null),
            ),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Идентификатор'),
            TextFormField(
              controller: _slug,
              decoration: const InputDecoration(
                hintText: 'manty-beef-classic',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Icon(LucideIcons.hash, size: 18),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Обязательно' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            const _SectionLabel('Категория'),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name('ru'))),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Название (RU / KK / EN)'),
            _i18nFields(_name, hintRu: 'Манты с говядиной'),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Описание'),
            _i18nFields(_desc, hintRu: 'Краткое описание...', maxLines: 3),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Состав'),
            _i18nFields(_ing, hintRu: 'Тесто, говядина, лук...', maxLines: 2),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Способ приготовления'),
            _i18nFields(_cook, hintRu: 'На пару 45 минут...', maxLines: 2),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('КБЖУ на 100 г'),
            Row(
              children: [
                _kbjuField(_kcal, 'ккал'),
                const SizedBox(width: AppSpacing.sm),
                _kbjuField(_protein, 'Б'),
                const SizedBox(width: AppSpacing.sm),
                _kbjuField(_fat, 'Ж'),
                const SizedBox(width: AppSpacing.sm),
                _kbjuField(_carb, 'У'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel('Варианты (метка / вес г / цена ₸)'),
            for (final v in _variants) ...[
              _VariantEditor(
                row: v,
                canDelete: _variants.length > 1,
                onDelete: () => setState(() {
                  v.dispose();
                  _variants.remove(v);
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _variants.add(_VariantRow.empty())),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Добавить вариант'),
            ),
            const SizedBox(height: AppSpacing.xl),

            SwitchListTile.adaptive(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              activeThumbColor: AppColors.gold,
              contentPadding: EdgeInsets.zero,
              title: const Text('Показывать в каталоге'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(isEdit ? 'Сохранить' : 'Создать'),
          ),
        ),
      ),
    );
  }

  Widget _i18nFields(
    Map<String, TextEditingController> map, {
    required String hintRu,
    int maxLines = 1,
  }) {
    Widget row(String code, TextEditingController c, String hint, String label) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextFormField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            labelText: label,
          ),
        ),
      );
    }

    return Column(
      children: [
        row('ru', map['ru']!, hintRu, 'RU'),
        row('kk', map['kk']!, '', 'KK'),
        row('en', map['en']!, '', 'EN'),
      ],
    );
  }

  Widget _kbjuField(TextEditingController c, String label) => Expanded(
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: AppTypography.caption(AppColors.textSecondary)
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      );
}

class _VariantRow {
  _VariantRow({
    required this.label,
    required this.weight,
    required this.priceKzt,
  });

  factory _VariantRow.empty() => _VariantRow(
        label: TextEditingController(),
        weight: TextEditingController(),
        priceKzt: TextEditingController(),
      );

  factory _VariantRow.fromDto(VariantDto v) => _VariantRow(
        label: TextEditingController(text: v.label),
        weight: TextEditingController(text: v.weightG.toString()),
        priceKzt: TextEditingController(text: (v.price.minor ~/ 100).toString()),
      );

  final TextEditingController label;
  final TextEditingController weight;
  final TextEditingController priceKzt;

  void dispose() {
    label.dispose();
    weight.dispose();
    priceKzt.dispose();
  }

  Map<String, dynamic> toJson() {
    final lbl = label.text.trim();
    final pr = (int.tryParse(priceKzt.text) ?? 0) * 100;
    return {
      'label': lbl,
      'label_i18n': {
        'ru': lbl.replaceAll('kg', 'кг').replaceAll('g', 'г').replaceAll('pcs', 'шт'),
        'kk': lbl.replaceAll('kg', 'кг').replaceAll('g', 'г').replaceAll('pcs', 'дана'),
        'en': lbl,
      },
      'weight_g': int.tryParse(weight.text) ?? 0,
      'price_minor': pr,
    };
  }
}

class _VariantEditor extends StatelessWidget {
  const _VariantEditor({
    required this.row,
    required this.canDelete,
    required this.onDelete,
  });

  final _VariantRow row;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.label,
              decoration: const InputDecoration(hintText: '0.5kg / 4 pcs'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'г'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.priceKzt,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '₸'),
            ),
          ),
          IconButton(
            onPressed: canDelete ? onDelete : null,
            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
          ),
        ],
      );
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final String imageUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: InkWell(
        onTap: uploading ? null : onPick,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: imageUrl.isEmpty
                  ? Container(
                      color: AppColors.surfaceMuted,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.imagePlus,
                              size: 36, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Загрузить фото',
                            style: AppTypography.bodyMedium(AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG / PNG / WebP / AVIF / GIF — до 8 MB',
                            style: AppTypography.caption(AppColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
            if (uploading)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            if (imageUrl.isNotEmpty && !uploading)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                    onPressed: onClear,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
