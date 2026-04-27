"""High-quality demo data for Aziza Food.

Prices in KZT minor units (1 KZT = 100 minor). 1500 ₸ = 150_000.
Translations: ru (default), kk (Kazakh), en.
"""

CATEGORIES = [
    {
        "slug": "manty",
        "sort": 1,
        "name_i18n": {"ru": "Манты", "kk": "Манты", "en": "Manty"},
    },
    {
        "slug": "pelmeni",
        "sort": 2,
        "name_i18n": {"ru": "Пельмени", "kk": "Пельмендер", "en": "Pelmeni"},
    },
    {
        "slug": "samsa",
        "sort": 3,
        "name_i18n": {"ru": "Самса", "kk": "Самса", "en": "Samsa"},
    },
    {
        "slug": "sauces",
        "sort": 4,
        "name_i18n": {"ru": "Соусы", "kk": "Тұздықтар", "en": "Sauces"},
    },
]


def _v(label: str, weight: int, price_kzt: int) -> dict:
    return {
        "label": label,
        "label_i18n": {
            "ru": label.replace("kg", "кг").replace("g", "г").replace("pcs", "шт"),
            "kk": label.replace("kg", "кг").replace("g", "г").replace("pcs", "дана"),
            "en": label,
        },
        "weight_g": weight,
        "price_minor": price_kzt * 100,
    }


# Stable Unsplash photo IDs verified by HEAD-request. Replace with custom
# food photography before launch. URL builder lives in `_img()`.
_UNSPLASH_BASE = "https://images.unsplash.com/photo-"
_UNSPLASH_OPTS = "?w=800&q=80&auto=format&fit=crop"


def _img(photo_id: str) -> str:
    return f"{_UNSPLASH_BASE}{photo_id}{_UNSPLASH_OPTS}"


IMAGES = {
    "manty-beef-classic": _img("1496116218417-1a781b1c416c"),
    "manty-lamb": _img("1563379091339-03b21ab4a4f8"),
    "manty-pumpkin": _img("1565299624946-b28f40a0ae38"),
    "manty-chicken": _img("1606491956689-2ea866880c84"),
    "pelmeni-classic": _img("1626844131082-256783844137"),
    "pelmeni-siberian": _img("1611250282006-4484dd3fba6b"),
    "pelmeni-fish": _img("1565958011703-44f9829ba187"),
    "samsa-beef": _img("1601050690597-df0568f70950"),
    "samsa-lamb": _img("1626804475297-41608ea09aeb"),
    "samsa-cheese-greens": _img("1584278858536-52532423b9ea"),
    "sauce-sour-cream": _img("1551782450-a2132b4ba21d"),
    "sauce-tomato-spicy": _img("1542528180-a1208c5169a5"),
    "sauce-vinegar": _img("1567620832903-9fc6debc209f"),
    "sauce-garlic-yogurt": _img("1565895405127-481853366cf8"),
}


PRODUCTS = [
    # ───────── MANTY ─────────
    {
        "slug": "manty-beef-classic",
        "category": "manty",
        "sort": 1,
        "name_i18n": {
            "ru": "Манты с говядиной",
            "kk": "Сиыр етті манты",
            "en": "Beef Manty",
        },
        "description_i18n": {
            "ru": "Классические манты, лепленные вручную, с сочной начинкой из мраморной говядины и лука. Готовятся на пару 45 минут.",
            "kk": "Қолмен жасалған классикалық манты, мраморлы сиыр еті мен пияздан жасалған шырынды толтырмамен. Буда 45 минут пісіріледі.",
            "en": "Hand-pleated classic manty filled with juicy marbled beef and onion. Steamed for 45 minutes.",
        },
        "ingredients_i18n": {
            "ru": "Тесто: мука высшего сорта, вода, соль. Начинка: говядина, лук, соль, перец.",
            "kk": "Қамыр: жоғары сұрыпты ұн, су, тұз. Толтырма: сиыр еті, пияз, тұз, бұрыш.",
            "en": "Dough: premium flour, water, salt. Filling: beef, onion, salt, pepper.",
        },
        "cooking_i18n": {
            "ru": "Поставьте на пар на 45 минут. Подавать со сметаной или соусом.",
            "kk": "Буда 45 минут пісіріңіз. Қаймақпен немесе тұздықпен беріңіз.",
            "en": "Steam for 45 minutes. Serve with sour cream or sauce.",
        },
        "kbju": {"kcal": 245, "protein": 11.2, "fat": 12.8, "carb": 22.1},
        "variants": [_v("0.5kg", 500, 2400), _v("1kg", 1000, 4500), _v("2kg", 2000, 8500)],
    },
    {
        "slug": "manty-lamb",
        "category": "manty",
        "sort": 2,
        "name_i18n": {
            "ru": "Манты с бараниной",
            "kk": "Қой етті манты",
            "en": "Lamb Manty",
        },
        "description_i18n": {
            "ru": "Аутентичные манты с молодой бараниной и курдючным жиром. Восточная классика по старинному рецепту.",
            "kk": "Жас қой еті мен құйрық майымен жасалған нағыз манты. Көне рецепт бойынша шығыстық классика.",
            "en": "Authentic manty with young lamb and tail fat. Eastern classic from a traditional recipe.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, баранина, курдючный жир, лук, соль, зира.",
            "kk": "Қамыр, қой еті, құйрық майы, пияз, тұз, зире.",
            "en": "Dough, lamb, tail fat, onion, salt, cumin.",
        },
        "cooking_i18n": {
            "ru": "На пару 50 минут. Идеально с уксусным соусом и зеленью.",
            "kk": "Буда 50 минут. Сірке тұздығымен және көкөніспен өте дәмді.",
            "en": "Steam for 50 minutes. Best with vinegar sauce and herbs.",
        },
        "kbju": {"kcal": 268, "protein": 10.4, "fat": 15.6, "carb": 21.8},
        "variants": [_v("0.5kg", 500, 2900), _v("1kg", 1000, 5500), _v("2kg", 2000, 10500)],
    },
    {
        "slug": "manty-pumpkin",
        "category": "manty",
        "sort": 3,
        "name_i18n": {
            "ru": "Манты с тыквой",
            "kk": "Асқабақты манты",
            "en": "Pumpkin Manty",
        },
        "description_i18n": {
            "ru": "Постные манты с медовой тыквой, луком и специями. Тонкое тесто, нежная сладковатая начинка.",
            "kk": "Балдай асқабақ, пияз және дәмдеуіштермен ораза манты. Жұқа қамыр, нәзік тәттілеу толтырма.",
            "en": "Lenten manty with honey pumpkin, onion and spices. Thin dough, tender sweet filling.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, тыква, лук, растительное масло, соль, перец.",
            "kk": "Қамыр, асқабақ, пияз, өсімдік майы, тұз, бұрыш.",
            "en": "Dough, pumpkin, onion, vegetable oil, salt, pepper.",
        },
        "cooking_i18n": {
            "ru": "На пару 40 минут. Подавайте с топлёным маслом.",
            "kk": "Буда 40 минут. Сары майдың үстіне беріңіз.",
            "en": "Steam for 40 minutes. Serve with melted butter.",
        },
        "kbju": {"kcal": 178, "protein": 4.2, "fat": 5.1, "carb": 28.4},
        "variants": [_v("0.5kg", 500, 1900), _v("1kg", 1000, 3500)],
    },
    {
        "slug": "manty-chicken",
        "category": "manty",
        "sort": 4,
        "name_i18n": {
            "ru": "Манты с курицей",
            "kk": "Тауық етті манты",
            "en": "Chicken Manty",
        },
        "description_i18n": {
            "ru": "Лёгкие манты с филе курицы, луком и зеленью. Низкокалорийный вариант без потери вкуса.",
            "kk": "Тауық еті, пияз және көкөністермен жеңіл манты. Дәмін жоғалтпаған аз калориялы нұсқа.",
            "en": "Light manty with chicken fillet, onion and herbs. Low-calorie option without losing flavor.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, куриное филе, лук, соль, перец, петрушка.",
            "kk": "Қамыр, тауық еті, пияз, тұз, бұрыш, ақжелкек.",
            "en": "Dough, chicken fillet, onion, salt, pepper, parsley.",
        },
        "cooking_i18n": {
            "ru": "На пару 35 минут. Подавайте с лимоном.",
            "kk": "Буда 35 минут. Лимонмен беріңіз.",
            "en": "Steam for 35 minutes. Serve with lemon.",
        },
        "kbju": {"kcal": 198, "protein": 13.5, "fat": 6.8, "carb": 21.0},
        "variants": [_v("0.5kg", 500, 2200), _v("1kg", 1000, 4200)],
    },
    # ───────── PELMENI ─────────
    {
        "slug": "pelmeni-classic",
        "category": "pelmeni",
        "sort": 1,
        "name_i18n": {
            "ru": "Пельмени классические",
            "kk": "Классикалық пельмендер",
            "en": "Classic Pelmeni",
        },
        "description_i18n": {
            "ru": "Домашние пельмени с фаршем из говядины и свинины 60/40. Тонкое тесто, сочная начинка.",
            "kk": "Сиыр және шошқа етінен 60/40 фаршпен үй пельмендері. Жұқа қамыр, шырынды толтырма.",
            "en": "Homemade pelmeni with 60/40 beef and pork mince. Thin dough, juicy filling.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, говядина, свинина, лук, соль, перец.",
            "kk": "Қамыр, сиыр еті, шошқа еті, пияз, тұз, бұрыш.",
            "en": "Dough, beef, pork, onion, salt, pepper.",
        },
        "cooking_i18n": {
            "ru": "Варить в подсоленной воде 7-8 минут после всплытия.",
            "kk": "Тұздалған суда қалқып шыққаннан кейін 7-8 минут қайнатыңыз.",
            "en": "Boil in salted water for 7-8 minutes after they surface.",
        },
        "kbju": {"kcal": 232, "protein": 11.8, "fat": 11.5, "carb": 21.4},
        "variants": [_v("0.5kg", 500, 1900), _v("1kg", 1000, 3600)],
    },
    {
        "slug": "pelmeni-siberian",
        "category": "pelmeni",
        "sort": 2,
        "name_i18n": {
            "ru": "Пельмени сибирские",
            "kk": "Сібір пельмендері",
            "en": "Siberian Pelmeni",
        },
        "description_i18n": {
            "ru": "Тройной фарш — говядина, свинина, баранина. Крупные, по 14 граммов каждый.",
            "kk": "Үш етті фарш — сиыр, шошқа, қой. Әрқайсысы 14 грамнан үлкен.",
            "en": "Triple meat blend — beef, pork, lamb. Large, 14g each.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, говядина, свинина, баранина, лук, лёд (для сочности), специи.",
            "kk": "Қамыр, сиыр, шошқа, қой еті, пияз, мұз (шырын үшін), дәмдеуіштер.",
            "en": "Dough, beef, pork, lamb, onion, ice (for juiciness), spices.",
        },
        "cooking_i18n": {
            "ru": "Варить 9 минут после всплытия.",
            "kk": "Қалқып шыққаннан кейін 9 минут қайнатыңыз.",
            "en": "Boil 9 minutes after surfacing.",
        },
        "kbju": {"kcal": 248, "protein": 12.4, "fat": 13.0, "carb": 20.8},
        "variants": [_v("0.5kg", 500, 2400), _v("1kg", 1000, 4600)],
    },
    {
        "slug": "pelmeni-fish",
        "category": "pelmeni",
        "sort": 3,
        "name_i18n": {
            "ru": "Пельмени с лососем",
            "kk": "Албырт пельмендер",
            "en": "Salmon Pelmeni",
        },
        "description_i18n": {
            "ru": "Деликатесные пельмени с филе атлантического лосося и сливочным маслом.",
            "kk": "Атлантикалық албырт еті мен сары майымен дәмді пельмендер.",
            "en": "Gourmet pelmeni with Atlantic salmon fillet and butter.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, лосось, лук-шалот, сливочное масло, лимон, укроп, соль.",
            "kk": "Қамыр, албырт, шалот пиязы, сары май, лимон, аскөк, тұз.",
            "en": "Dough, salmon, shallot, butter, lemon, dill, salt.",
        },
        "cooking_i18n": {
            "ru": "Варить 6 минут после всплытия. Подавайте со сметаной.",
            "kk": "Қалқып шыққаннан кейін 6 минут қайнатыңыз.",
            "en": "Boil 6 minutes after surfacing. Serve with sour cream.",
        },
        "kbju": {"kcal": 215, "protein": 13.2, "fat": 9.1, "carb": 20.5},
        "variants": [_v("0.5kg", 500, 3200), _v("1kg", 1000, 6200)],
    },
    # ───────── SAMSA ─────────
    {
        "slug": "samsa-beef",
        "category": "samsa",
        "sort": 1,
        "name_i18n": {
            "ru": "Самса с говядиной",
            "kk": "Сиыр етті самса",
            "en": "Beef Samsa",
        },
        "description_i18n": {
            "ru": "Слоёная самса из тандыра с рубленой говядиной и луком. Хрустящая корочка, сочная начинка.",
            "kk": "Тандырдан шығатын ұсақталған сиыр еті мен пияздан жасалған қабатты самса. Қытырлақ қабық, шырынды толтырма.",
            "en": "Tandyr-baked layered samsa with chopped beef and onion. Crispy crust, juicy filling.",
        },
        "ingredients_i18n": {
            "ru": "Слоёное тесто, говядина, лук, кунжут, чёрный тмин, яйцо.",
            "kk": "Қабатты қамыр, сиыр еті, пияз, күнжіт, қара зире, жұмыртқа.",
            "en": "Puff pastry, beef, onion, sesame, nigella, egg.",
        },
        "cooking_i18n": {
            "ru": "Разогрейте в духовке 8 минут при 200°C.",
            "kk": "Пеште 200°C-та 8 минут жылытыңыз.",
            "en": "Reheat in oven for 8 minutes at 200°C.",
        },
        "kbju": {"kcal": 285, "protein": 9.8, "fat": 16.4, "carb": 24.2},
        "variants": [_v("4 pcs", 480, 1800), _v("8 pcs", 960, 3500)],
    },
    {
        "slug": "samsa-lamb",
        "category": "samsa",
        "sort": 2,
        "name_i18n": {
            "ru": "Самса с бараниной",
            "kk": "Қой етті самса",
            "en": "Lamb Samsa",
        },
        "description_i18n": {
            "ru": "Узбекская самса с молодой бараниной, курдюком и зирой. Печётся в настоящем тандыре.",
            "kk": "Жас қой еті, құйрық майы және зирамен өзбек самсасы. Нағыз тандырда пісіріледі.",
            "en": "Uzbek samsa with young lamb, tail fat and cumin. Baked in a real tandyr.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, баранина, курдюк, лук, зира, соль, перец.",
            "kk": "Қамыр, қой еті, құйрық, пияз, зире, тұз, бұрыш.",
            "en": "Dough, lamb, tail fat, onion, cumin, salt, pepper.",
        },
        "cooking_i18n": {
            "ru": "В духовке 10 минут при 200°C.",
            "kk": "Пеште 200°C-та 10 минут.",
            "en": "Oven 10 minutes at 200°C.",
        },
        "kbju": {"kcal": 312, "protein": 10.2, "fat": 19.5, "carb": 23.8},
        "variants": [_v("4 pcs", 480, 2200), _v("8 pcs", 960, 4200)],
    },
    {
        "slug": "samsa-cheese-greens",
        "category": "samsa",
        "sort": 3,
        "name_i18n": {
            "ru": "Самса с сыром и зеленью",
            "kk": "Ірімшік пен көкөністі самса",
            "en": "Cheese & Greens Samsa",
        },
        "description_i18n": {
            "ru": "Постная самса с сыром сулугуни, шпинатом и зеленью. Воздушное тесто.",
            "kk": "Сулугуни ірімшігі, шпинат және көкөністермен ораза самса. Ауалы қамыр.",
            "en": "Lenten samsa with suluguni cheese, spinach and herbs. Airy dough.",
        },
        "ingredients_i18n": {
            "ru": "Тесто, сулугуни, шпинат, петрушка, укроп, кинза, соль.",
            "kk": "Қамыр, сулугуни, шпинат, ақжелкек, аскөк, киндза, тұз.",
            "en": "Dough, suluguni, spinach, parsley, dill, cilantro, salt.",
        },
        "cooking_i18n": {
            "ru": "В духовке 7 минут при 200°C.",
            "kk": "Пеште 200°C-та 7 минут.",
            "en": "Oven 7 minutes at 200°C.",
        },
        "kbju": {"kcal": 254, "protein": 11.4, "fat": 12.8, "carb": 23.1},
        "variants": [_v("4 pcs", 440, 1900)],
    },
    # ───────── SAUCES ─────────
    {
        "slug": "sauce-sour-cream",
        "category": "sauces",
        "sort": 1,
        "name_i18n": {
            "ru": "Сметанный соус с зеленью",
            "kk": "Көкөністі қаймақ тұздығы",
            "en": "Sour Cream Herb Sauce",
        },
        "description_i18n": {
            "ru": "Густая фермерская сметана с укропом, чесноком и солью. Идеально к мантам и пельменям.",
            "kk": "Аскөк, сарымсақ және тұзымен қалың фермерлік қаймақ. Манты мен пельмендерге өте жақсы келеді.",
            "en": "Thick farm sour cream with dill, garlic and salt. Perfect with manty and pelmeni.",
        },
        "ingredients_i18n": {
            "ru": "Сметана 30%, укроп, чеснок, соль.",
            "kk": "Қаймақ 30%, аскөк, сарымсақ, тұз.",
            "en": "Sour cream 30%, dill, garlic, salt.",
        },
        "cooking_i18n": {
            "ru": "Подавайте охлаждённым.",
            "kk": "Салқын күйінде беріңіз.",
            "en": "Serve chilled.",
        },
        "kbju": {"kcal": 245, "protein": 2.8, "fat": 24.5, "carb": 3.4},
        "variants": [_v("200g", 200, 600), _v("500g", 500, 1300)],
    },
    {
        "slug": "sauce-tomato-spicy",
        "category": "sauces",
        "sort": 2,
        "name_i18n": {
            "ru": "Острый томатный соус",
            "kk": "Ащы қызанақ тұздығы",
            "en": "Spicy Tomato Sauce",
        },
        "description_i18n": {
            "ru": "Свежие томаты с чесноком, кинзой и красным перцем. Разогревает.",
            "kk": "Жаңа қызанақ, сарымсақ, киндза және қызыл бұрышпен. Жылытады.",
            "en": "Fresh tomatoes with garlic, cilantro and red pepper. Warming.",
        },
        "ingredients_i18n": {
            "ru": "Томаты, чеснок, кинза, красный перец, соль, оливковое масло.",
            "kk": "Қызанақ, сарымсақ, киндза, қызыл бұрыш, тұз, зәйтүн майы.",
            "en": "Tomatoes, garlic, cilantro, red pepper, salt, olive oil.",
        },
        "cooking_i18n": {
            "ru": "Подавайте при комнатной температуре.",
            "kk": "Бөлме температурасында беріңіз.",
            "en": "Serve at room temperature.",
        },
        "kbju": {"kcal": 78, "protein": 1.4, "fat": 4.8, "carb": 7.2},
        "variants": [_v("200g", 200, 700)],
    },
    {
        "slug": "sauce-vinegar",
        "category": "sauces",
        "sort": 3,
        "name_i18n": {
            "ru": "Уксусный соус с луком",
            "kk": "Пияз қосылған сірке тұздығы",
            "en": "Onion Vinegar Sauce",
        },
        "description_i18n": {
            "ru": "Классический спутник мантов: винный уксус, маринованный лук, чёрный перец.",
            "kk": "Манты үшін классикалық тұздық: жүзім сірке суы, маринадталған пияз, қара бұрыш.",
            "en": "Classic manty companion: wine vinegar, pickled onion, black pepper.",
        },
        "ingredients_i18n": {
            "ru": "Винный уксус, лук, перец, сахар, соль.",
            "kk": "Жүзім сірке суы, пияз, бұрыш, қант, тұз.",
            "en": "Wine vinegar, onion, pepper, sugar, salt.",
        },
        "cooking_i18n": {
            "ru": "Подавайте охлаждённым.",
            "kk": "Салқын күйінде беріңіз.",
            "en": "Serve chilled.",
        },
        "kbju": {"kcal": 32, "protein": 0.6, "fat": 0.1, "carb": 7.0},
        "variants": [_v("200g", 200, 500)],
    },
    {
        "slug": "sauce-garlic-yogurt",
        "category": "sauces",
        "sort": 4,
        "name_i18n": {
            "ru": "Йогуртовый соус с чесноком",
            "kk": "Сарымсақты йогурт тұздығы",
            "en": "Garlic Yogurt Sauce",
        },
        "description_i18n": {
            "ru": "Натуральный йогурт с чесноком, лимоном и оливковым маслом. Освежает.",
            "kk": "Сарымсақ, лимон және зәйтүн майымен табиғи йогурт. Сергітеді.",
            "en": "Natural yogurt with garlic, lemon and olive oil. Refreshing.",
        },
        "ingredients_i18n": {
            "ru": "Йогурт, чеснок, лимон, оливковое масло, мята, соль.",
            "kk": "Йогурт, сарымсақ, лимон, зәйтүн майы, жалбыз, тұз.",
            "en": "Yogurt, garlic, lemon, olive oil, mint, salt.",
        },
        "cooking_i18n": {
            "ru": "Подавайте охлаждённым.",
            "kk": "Салқын күйінде беріңіз.",
            "en": "Serve chilled.",
        },
        "kbju": {"kcal": 92, "protein": 3.5, "fat": 6.8, "carb": 4.6},
        "variants": [_v("200g", 200, 700)],
    },
]


PROMOS = [
    {"code": "WELCOME10", "type": "percent", "value": 10, "min_order_minor": 200_000},
    {"code": "FREEDLV", "type": "free_delivery", "value": 0, "min_order_minor": 300_000},
    {"code": "AZIZA1500", "type": "amount", "value": 150_000, "min_order_minor": 500_000},
]
