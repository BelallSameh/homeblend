// main.dart  (HomeBlend)  ---  Per-user cart/favorites + product code display
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'dart:math'   as math;            // keep if you removed it by mistake

// Single import for ALL AR classes:
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:ar_flutter_plugin/models/ar_anchor.dart';    // for ARPlaneAnchor

extension TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length - math.min(length, n));
}

late List<CameraDescription> cameras;

Future<void> main() async {
  //Gemini.init(apiKey: 'AIzaSyD1yfNIHnLvjEL0Fm8DiAtaur7lj1GGkFw');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await availableCameras().then((value) => cameras = value);

  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  runApp(const RootApp());
}

/// =======================================================================
/// SIMPLE LOCALIZATION (unchanged strings except you can restore any custom)
/// =======================================================================
class S {
  final Locale locale;
  S(this.locale);
  static const supported = [Locale('en'), Locale('ar')];
  static S of(BuildContext c) => Localizations.of<S>(c, S) ?? S(const Locale('en'));
  static final _vals = {
    'en': {
      'appTitle': 'HomeBlend',
      'welcomeHeadline': 'HomeBlend',
      'welcomeSubtitle': 'Curated furniture & décor.\nInnovating Home, Inspiring Lifestyle.\nSign in or create an account to explore.',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'name': 'Full Name',
      'createAccount': 'Create Account',
      'continueGoogle': 'Continue With Google',
      'continueFacebook': 'Continue With Facebook',
      'continuePhone': 'Continue With Phone',
      'agreeTerms': 'agreeTerms',
      'logout': 'Logout',
      'catalog': 'Catalog',
      'home': 'Home',
      'cart': 'Cart',
      'profile': 'Profile',
      'favorites': 'Favourites',
      'products': 'Products',
      'categories': 'Categories',
      'cartItems': 'Cart Items',
      'goToCatalog': 'Browse Catalog',
      'searchHint': 'Search products...',
      'noResults': 'No products match.',
      'addToCart': 'Add to Cart',
      'addMore': 'Add More',
      'checkout': 'Checkout',
      'cartEmpty': 'Cart is empty.\nAdd something you love!',
      'clear': 'Clear',
      'subtotal': 'Subtotal',
      'delivery': 'Delivery',
      'total': 'Total',
      'checkoutMock': 'This feature will be available in an upcoming update.',
      'scanQr': 'Scan QR',
      'qrTitle': 'Scan QR Code',
      'manualCode': 'Manual Code',
      'notFound': 'Product Not Found',
      'close': 'Close',
      'required': 'Required',
      'invalidEmail': 'Invalid email',
      'passwordShort': 'Min 6 chars',
      'passwordMismatch': 'Mismatch',
      'orEmailLogin': 'Use Email / Password',
      'langToggle': 'Arabic / English',
      'darkMode': 'Dark Mode',
      'variants': 'Variants',
      'description': 'Description',
      'price': 'Price',
      'code': 'Code',
      'category': 'Category',
      "forgotPassword": "Forgot Password?"
},
    'ar': {
      'appTitle': 'هوم بليند',
      'welcomeHeadline': 'هوم بليند',
      'welcomeSubtitle':  'أثاث وديكور مختار بعناية. سجّل الدخول أو أنشئ حساباً للاستكشاف.',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'name': 'الاسم الكامل',
      'createAccount': 'إنشاء حساب',
      'continueGoogle': 'Continue With Google',
      'continueFacebook': 'Continue With Facebook',
      'continuePhone': 'Continue With Phone',
      'agreeTerms': 'agreeTerms',
      'logout': 'تسجيل الخروج',
      'catalog': 'الكتالوج',
      'home': 'الرئيسية',
      'cart': 'السلة',
      'profile': 'الملف',
      'favorites': 'المفضلة',
      'products': 'منتجات',
      'categories': 'فئات',
      'cartItems': 'عناصر',
      'goToCatalog': 'تصفح الكتالوج',
      'searchHint': 'بحث...',
      'noResults': 'لا توجد نتائج',
      'addToCart': 'أضف للسلة',
      'addMore': 'أضف المزيد',
      'checkout': 'الدفع',
      'cartEmpty': 'السلة فارغة',
      'clear': 'مسح',
      'subtotal': 'الإجمالي الفرعي',
      'delivery': 'التوصيل',
      'total': 'الإجمالي',
      'checkoutMock': 'عرض فقط',
      'scanQr': 'مسح QR',
      'qrTitle': 'مسح QR',
      'manualCode': 'كود يدوي',
      'notFound': 'غير موجود',
      'close': 'إغلاق',
      'required': 'مطلوب',
      'invalidEmail': 'بريد غير صالح',
      'passwordShort': '٦ أحرف على الأقل',
      'passwordMismatch': 'عدم تطابق',
      'orEmailLogin': 'استخدم البريد / كلمة المرور',
      'langToggle': 'عربي / إنجليزي',
      'darkMode': 'الوضع الداكن',
      'variants': 'الخيارات',
      'description': 'الوصف',
      'price': 'السعر',
      'code': 'الكود',
      'category': 'الفئة',
      "forgotPassword": "هل نسيت كلمة السر؟"

}
  };
  String t(String k) => _vals[locale.languageCode]?[k] ?? _vals['en']![k] ?? k;
}

class _LocDelegate extends LocalizationsDelegate<S> {
  const _LocDelegate();
  @override
  bool isSupported(Locale l) => S.supported.any((e) => e.languageCode == l.languageCode);
  @override
  Future<S> load(Locale l) async => S(l);
  @override
  bool shouldReload(_) => false;
}

/// =======================================================================
/// THEME  (keep your palette)
/// =======================================================================
class AppColors extends ThemeExtension<AppColors> {
  final Color bg, surface, surfaceAlt, cardLightBrown, primary, primaryDeep, accentGold, error;
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.cardLightBrown,
    required this.primary,
    required this.primaryDeep,
    required this.accentGold,
    required this.error,
  });
  static AppColors light() => const AppColors(
    bg: Color(0xFFF9F3EC),
    surface: Color(0xFFEFE3D6),
    surfaceAlt: Color(0xFFE4D6C7),
    cardLightBrown: Color(0xFFDBC6B5),
    primary: Color(0xFF6F452B),
    primaryDeep: Color(0xFF3C2416),
    accentGold: Color(0xFFC79A4C),
    error: Color(0xFFC0392B),
  );
  static AppColors dark() => const AppColors(
    bg: Color(0xFF12100F),
    surface: Color(0xFF1E1A18),
    surfaceAlt: Color(0xFF2A2421),
    cardLightBrown: Color(0xFFC89E73),
    primary: Color(0xFFBF8756),
    primaryDeep: Color(0xFF28170F),
    accentGold: Color(0xFFD6A75C),
    error: Color(0xFFFF5549),
  );
  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? cardLightBrown,
    Color? primary,
    Color? primaryDeep,
    Color? accentGold,
    Color? error,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        cardLightBrown: cardLightBrown ?? this.cardLightBrown,
        primary: primary ?? this.primary,
        primaryDeep: primaryDeep ?? this.primaryDeep,
        accentGold: accentGold ?? this.accentGold,
        error: error ?? this.error,
      );
  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) => this;
}

ThemeData buildTheme({required bool dark}) {
  final palette = dark ? AppColors.dark() : AppColors.light();
  final base = dark ? ThemeData.dark() : ThemeData.light();
  final display = GoogleFonts.plusJakartaSans;
  final body = GoogleFonts.inter;
  final textTheme = base.textTheme.copyWith(
    headlineSmall: display(fontSize: 28, fontWeight: FontWeight.w800),
    titleLarge: display(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: display(fontSize: 18, fontWeight: FontWeight.w700),
    titleSmall: display(fontSize: 15, fontWeight: FontWeight.w700),
    bodyLarge: body(fontSize: 16, height: 1.34),
    bodyMedium: body(fontSize: 14, height: 1.33),
    bodySmall: body(fontSize: 12, height: 1.25),
    labelLarge: body(fontSize: 14, fontWeight: FontWeight.w700),
    labelMedium: body(fontSize: 12, fontWeight: FontWeight.w600),
  );
  final radius = 24.0;
  ButtonStyle makeButton(Color bg, Color fg) => ButtonStyle(
    minimumSize: const MaterialStatePropertyAll(Size.fromHeight(54)),
    shape: MaterialStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) return bg.withOpacity(.35);
      if (states.contains(MaterialState.pressed)) return bg.withOpacity(.90);
      return bg;
    }),
    foregroundColor: MaterialStatePropertyAll(fg),
    overlayColor: MaterialStatePropertyAll(fg.withOpacity(.10)),
    textStyle: MaterialStatePropertyAll(body(fontSize: 15, fontWeight: FontWeight.w700)),
  );
  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: palette.bg,
    extensions: [palette],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium!.copyWith(color: dark ? Colors.white : palette.primaryDeep),
      foregroundColor: dark ? Colors.white : palette.primaryDeep,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: makeButton(palette.primary, Colors.white)),
    filledButtonTheme: FilledButtonThemeData(style: makeButton(palette.accentGold, palette.primaryDeep)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size.fromHeight(52)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
        side: MaterialStatePropertyAll(
            BorderSide(color: palette.primary.withOpacity(.55), width: 1.2)),
        foregroundColor:
        MaterialStatePropertyAll(dark ? Colors.white : palette.primaryDeep),
        overlayColor: MaterialStatePropertyAll(palette.primary.withOpacity(.10)),
        textStyle:
        MaterialStatePropertyAll(body(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: palette.primaryDeep.withOpacity(.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: palette.primary, width: 1.6),
      ),
      hintStyle: textTheme.bodyMedium!.copyWith(
        color: dark
            ? Colors.white.withOpacity(.55)
            : palette.primaryDeep.withOpacity(.55),
        fontWeight: FontWeight.w500,
      ),
      labelStyle: textTheme.labelLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: dark ? Colors.black : palette.surface,
      selectedItemColor: palette.primary,
      unselectedItemColor:
      (dark ? Colors.white : palette.primaryDeep).withOpacity(.55),
      selectedLabelStyle:
      body(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .2),
      unselectedLabelStyle: body(fontSize: 11, fontWeight: FontWeight.w600),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    dividerTheme: DividerThemeData(
      color: (dark ? Colors.white : palette.primaryDeep).withOpacity(.18),
      space: 24,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.primaryDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
      contentTextStyle: body(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}
/// =======================================================================
/// MODELS + APP STATE  (Modified for per-user persistence)
/// =======================================================================
class Product {
  final String id;
  final String linkCode;
  final String name;
  final String company;
  final String category;
  final String height;
  final String width;
  final String description;
  final double price;
  final List<double> allPrices;
  final List<String> variantDescriptions; // aligns with allPrices
  final List<String> images;
  final List<String> drive;
  final double rating;
  final bool missing;
  final bool supportsAR;

  const Product({
    required this.id,
    required this.linkCode,
    required this.name,
    required this.company,
    required this.category,
    required this.height,
    required this.width,
    required this.description,
    required this.price,
    required this.allPrices,
    required this.variantDescriptions,
    required this.images,
    required this.drive,
    required this.rating,
    this.missing = false,
    this.supportsAR = false,
  });

  const Product.missing()
      : id = '_missing',
        linkCode = '',
        name = 'N/A',
        company = '',
        category = '',
        height = '',
        width = '',
        description = 'Not found',
        price = 0,
        allPrices = const [],
        variantDescriptions = const [],
        images = const [],
        drive = const [],
        rating = 0,
        missing = true,
        supportsAR = false;
  Map<String, dynamic> toJson() => {
    'id': id,
    'linkCode': linkCode,
    'name': name,
    'company': company,
    'category': category,
    'height': height,
    'width': width,
    'description': description,
    'price': price,
    'allPrices': allPrices,
    'variantDescriptions': variantDescriptions,
    'images': images,
    'drive': drive,
    'rating': rating,
    'missing': missing,
    'supportsAR': supportsAR,
  };

  factory Product.fromJson(Map<String, dynamic> j) {
    final rawAP = (j['allPrices'] is List) ? (j['allPrices'] as List) : const [];
    final ap = rawAP.whereType<num>().map((n) => n.toDouble()).toList();
    // parse multiple description segments: if description contains commas that map to variants
    List<String> variantDescs = [];
    if (j['multi'] is List) {
      variantDescs = (j['multi'] as List).whereType<String>().toList();
    } else {
      // Fallback: split description by commas if multiple
      final desc = (j['description'] ?? '') as String;
      if (desc.contains(',')) {
        variantDescs = desc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }
    // align lengths
    if (variantDescs.length != ap.length || ap.isEmpty) {
      // ensure at least one variant matching base price
      if (variantDescs.isEmpty) variantDescs = ['Default'];
      if (ap.isEmpty) ap.add((j['price'] is num) ? (j['price'] as num).toDouble() : 0.0);
    }
    final lowest = ap.isNotEmpty
        ? ap.reduce((a, b) => a < b ? a : b)
        : (j['price'] is num ? (j['price'] as num).toDouble() : 0.0);
    return Product(
      id: (j['id'] ?? '').toString(),
      linkCode: (j['linkCode'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      company: (j['company'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      height: (j['height'] ?? '').toString(),
      width: (j['width'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      price: lowest.toDouble(),
      allPrices: ap,
      variantDescriptions: variantDescs,
      images: (j['images'] is List)
          ? (j['images'] as List).whereType<String>().toList()
          : const [],
      drive: (j['drive'] is List)
          ? (j['drive'] as List).whereType<String>().toList()
          : const [],
      rating: (j['rating'] is num)
          ? (j['rating'] as num).toDouble()
          : (3 + Random(j.hashCode).nextDouble() * 2),
      supportsAR: j['ar'] == true ||        // JSON bool
          (j['company'] ?? '') == 'Cocolina' || (j['company'] ?? '') == 'Rozzitte'
    );
  }
}

class CartLine {
  final Product product;
  final int qty;
  final String variant; // NEW
  const CartLine({required this.product, required this.qty, this.variant = 'Default'});
  CartLine copyWith({Product? product, int? qty, String? variant}) =>
      CartLine(product: product ?? this.product, qty: qty ?? this.qty, variant: variant ?? this.variant);
}

/// AppState with per-user persistence
class AppState extends ChangeNotifier {
  AppState({required this.localeChanger, required this.dark}) {
    _authSub = FirebaseAuth.instance.userChanges().listen(_onUserChanged);
  }

  final VoidCallback localeChanger;
  final ValueNotifier<bool> dark;
  double priceOf(CartLine l) {
    if (l.variant != 'Default') {
      final idx = l.product.variantDescriptions.indexOf(l.variant);
      if (idx >= 0 && idx < l.product.allPrices.length) {
        return l.product.allPrices[idx];
      }
    }
    return l.product.price; // fallback to lowest / base price
  }


  // Products
  final List<Product> _products = [];
  bool _productsLoaded = false;

  // UI filters
  String _search = '';
  String _cat = 'All';

  // Cart & favorites (per user)
  final List<CartLine> _cart = [];
  final Set<String> _favorites = {};

  // user / persistence
  StreamSubscription<User?>? _authSub;
  String? _currentUid;
  Timer? _saveDebounce;

  // public getters
  List<Product> get products {
    final filteredCat =
    _cat == 'All' ? _products : _products.where((p) => p.category == _cat);
    if (_search.isEmpty) return filteredCat.toList();
    final q = _search.toLowerCase();
    return filteredCat
        .where((p) =>
    p.name.toLowerCase().contains(q) ||
        p.id.toLowerCase().contains(q) ||
        p.linkCode.toLowerCase().contains(q) ||
        p.variantDescriptions.any((d) => d.toLowerCase().contains(q)))
        .toList();
  }

  List<String> get categories =>
      ['All', ..._products.map((p) => p.category).toSet()];
  String get selectedCategory => _cat;
  List<CartLine> get cart => List.unmodifiable(_cart);
  Set<String> get favorites => _favorites;

  double get subtotal =>
      _cart.fold(0, (s, l) => s + priceOf(l) * l.qty);
  double get delivery => _cart.isEmpty ? 0 : 40;
  double get total => subtotal + delivery;

  bool get productsLoaded => _productsLoaded;

  // filter setters
  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setCategory(String c) {
    if (_cat == c) return;
    _cat = c;
    notifyListeners();
  }

  // product loading
  Future<void> loadProductsIfNeeded() async {
    if (_productsLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/products.json');
      final data = json.decode(raw);
      if (data is List) {
        _products.clear();
        _products.addAll(data.map((e) => Product.fromJson(e)).toList());
      }
      _productsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Load products error: $e');
    }
  }

  Product find(String raw) {
    if (raw.isEmpty) return const Product.missing();

    // 1) Trim & lowercase
    String code = raw.trim();

    // 2) If it's a full URL, try to extract ?id=XXXX (or last path /exec?id=)
    if (code.startsWith('http')) {
      try {
        final uri = Uri.parse(code);
        // Try query param 'id'
        final qp = uri.queryParameters['id'];
        if (qp != null && qp.trim().isNotEmpty) {
          code = qp.trim();
        } else {
          // fallback: last path segment or anything after last '='
          if (code.contains('=')) {
            code = code.split('=').last.trim();
          } else {
            final segs = uri.pathSegments;
            if (segs.isNotEmpty) {
              code = segs.last.trim();
            }
          }
        }
      } catch (_) {
        // ignore parse error
      }
    }

    // 3) Normalize hyphens & whitespace for matching (optional)
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll('\u200f', '').replaceAll(' ', '');

    final target = norm(code);

    for (final p in _products) {
      final idN = norm(p.id);
      final linkCodeN = norm(p.linkCode);
      if (idN == target || linkCodeN == target) return p;
    }

    // 4) Fallback: partial contains (if you want)
    for (final p in _products) {
      final idN = norm(p.id);
      final linkCodeN = norm(p.linkCode);
      if (idN.contains(target) || linkCodeN.contains(target)) return p;
    }

    return const Product.missing();
  }


  // cart ops
  void addToCart(Product p, {String variant = 'Default'}) {
    final i = _cart.indexWhere(
            (l) => l.product.id == p.id && l.variant == variant);
    if (i == -1) {
      _cart.add(CartLine(product: p, qty: 1, variant: variant));
    } else {
      _cart[i] = _cart[i].copyWith(qty: _cart[i].qty + 1);
    }
    _scheduleSave();
    notifyListeners();
  }

  void decrease(Product p, {String variant = 'Default'}) {
    final i = _cart.indexWhere(
            (l) => l.product.id == p.id && l.variant == variant);
    if (i == -1) return;
    final line = _cart[i];
    if (line.qty <= 1) {
      _cart.removeAt(i);
    } else {
      _cart[i] = line.copyWith(qty: line.qty - 1);
    }
    _scheduleSave();
    notifyListeners();
  }

  void remove(Product p, {String variant = 'Default'}) {
    _cart.removeWhere(
            (l) => l.product.id == p.id && l.variant == variant);
    _scheduleSave();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _scheduleSave();
    notifyListeners();
  }

  // favorites
  bool isFav(String id) => _favorites.contains(id);
  void toggleFav(Product p) {
    if (_favorites.contains(p.id)) {
      _favorites.remove(p.id);
    } else {
      _favorites.add(p.id);
    }
    _scheduleSave();
    notifyListeners();
  }

  // user change load/save
  Future<void> _onUserChanged(User? u) async {
    await _flushSave(); // flush old
    _cart.clear();
    _favorites.clear();
    _currentUid = u?.uid;
    if (_currentUid != null) {
      await _loadUserMeta();
    }
    notifyListeners();
  }

  Future<void> _loadUserMeta() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_meta')
          .doc(_currentUid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final favs =
            (data['favorites'] as List?)?.whereType<String>().toList() ?? [];
        _favorites.addAll(favs);
        final cartList = (data['cart'] as List?) ?? [];
        for (final raw in cartList) {
          if (raw is Map) {
            final id = raw['id'] as String? ?? '';
            final variant = raw['variant'] as String? ?? 'Default';
            final qtyRaw = raw['qty'];
            final qty = qtyRaw is int
                ? qtyRaw
                : int.tryParse(qtyRaw?.toString() ?? '') ?? 1;
            final p = find(id);
            if (!p.missing && qty > 0) {
              _cart.add(CartLine(product: p, qty: qty, variant: variant));
            }
          }
        }
      } else {
        await FirebaseFirestore.instance
            .collection('user_meta')
            .doc(_currentUid)
            .set({
          'favorites': [],
          'cart': [],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Load meta error: $e');
    }
  }

  void _scheduleSave() {
    if (_currentUid == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _flushSave);
  }

  Future<void> _flushSave() async {
    if (_currentUid == null) return;
    try {
      final cartPayload = _cart
          .map((l) => {
        'id': l.product.id,
        'variant': l.variant,
        'qty': l.qty,
      })
          .toList();
      await FirebaseFirestore.instance
          .collection('user_meta')
          .doc(_currentUid)
          .set({
        'favorites': _favorites.toList(),
        'cart': cartPayload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save meta error: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState state, required Widget child})
      : super(notifier: state, child: child);
  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}

/// =======================================================================
/// ROOT APP + AUTH GATE
/// =======================================================================
class RootApp extends StatefulWidget {
  const RootApp({super.key});
  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  Locale? _locale;
  final ValueNotifier<bool> _dark = ValueNotifier(false);

  void toggleLocale() {
    setState(() {
      if (_locale == null) {
        _locale = const Locale('ar');
      } else {
        _locale = _locale!.languageCode == 'ar'
            ? const Locale('en')
            : const Locale('ar');
      }
    });
  }

  late final AppState _appState =
  AppState(localeChanger: toggleLocale, dark: _dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _dark,
      builder: (_, dark, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HomeBlend',
          theme: buildTheme(dark: dark),
          locale: _locale,
          supportedLocales: S.supported,
          localizationsDelegates: const [
            _LocDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final lang = Localizations.localeOf(context).languageCode;
            return AppStateScope(
              state: _appState,
              child: Directionality(
                textDirection:
                lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              ),
            );
          },
          home: const AuthGate(child: MainShell()),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == null ? const StartAuthScreen() : child;
      },
    );
  }
}

/// =======================================================================
/// AUTH SCREEN  (Only minimal logic kept)
/// =======================================================================
class StartAuthScreen extends StatefulWidget {
  const StartAuthScreen({super.key});
  @override
  State<StartAuthScreen> createState() => _StartAuthScreenState();
}

class _StartAuthScreenState extends State<StartAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _emailPane = false;
  bool _obscure = true;
  bool _loadingLogin = false;
  bool _loadingSignup = false;
  bool _acceptedTerms = false;


  final emailLogin = TextEditingController();
  final passLogin = TextEditingController();
  final nameSignup = TextEditingController();
  final emailSignup = TextEditingController();
  final passSignup = TextEditingController();
  final confirmSignup = TextEditingController();
  final signupKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    emailLogin.dispose();
    passLogin.dispose();
    nameSignup.dispose();
    emailSignup.dispose();
    passSignup.dispose();
    confirmSignup.dispose();
    super.dispose();
  }

  S get s => S.of(context);
  void snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> googleAuth() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final gUser = await GoogleSignIn().signIn();
        if (gUser == null) return;
        final gAuth = await gUser.authentication;
        final cred = GoogleAuthProvider.credential(
            idToken: gAuth.idToken, accessToken: gAuth.accessToken);
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null &&
          (user.displayName ?? '').trim().isEmpty &&
          (user.email ?? '').isNotEmpty) {
        final base = user.email!.split('@').first;
        final pretty =
        base.isEmpty ? 'User' : base[0].toUpperCase() + base.substring(1);
        await user.updateDisplayName(pretty);
      }
    } catch (e) {
      snack(e.toString());
    }
  }

  Future<void> emailLoginFn() async {
    setState(() => _loadingLogin = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailLogin.text.trim(),
        password: passLogin.text,
      );
    } on FirebaseAuthException catch (e) {
      snack(e.message ?? 'Auth error');
    } finally {
      if (mounted) setState(() => _loadingLogin = false);
    }
  }

  Future<void> signupFn() async {
    if (!signupKey.currentState!.validate()) return;
    setState(() => _loadingSignup = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailSignup.text.trim(),
        password: passSignup.text,
      );
      await cred.user?.updateDisplayName(nameSignup.text.trim());
    } on FirebaseAuthException catch (e) {
      snack(e.message ?? 'Signup error');
    } finally {
      if (mounted) setState(() => _loadingSignup = false);
    }
  }

  String? validate(String? v,
      {bool email = false, bool pass = false, bool confirm = false}) {
    if (v == null || v.trim().isEmpty) return s.t('required');
    if (email && !RegExp(r'.+@.+').hasMatch(v)) return s.t('invalidEmail');
    if (pass && v.length < 6) return s.t('passwordShort');
    if (confirm && v != passSignup.text) return s.t('passwordMismatch');
    return null;
  }

  void _resetPassword() async {
    final email = emailLogin.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final headerH = media.size.height < 700 ? 200.0 : 240.0;
    final viewInsets = media.viewInsets.bottom;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: headerH,
              width: double.infinity,
              child: ClipPath(
                clipper: _CurvedClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        pal.primaryDeep,
                        pal.primary.withOpacity(.95),
                        pal.accentGold.withOpacity(.75)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(s.t('welcomeHeadline'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            s.t('welcomeSubtitle'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                              color: Colors.white.withOpacity(.90),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _ModeTabs(controller: _tabs),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildLoginPanel(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildSignupPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPanel() {
    final s = this.s;
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accentTxt = TextStyle(
        fontWeight: FontWeight.w700,
        color: dark ? pal.accentGold : pal.primaryDeep);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HBPrimaryButton(
            label: s.t('continueGoogle'),
            icon: Icons.g_mobiledata_rounded,
            onPressed: _loadingLogin ? null : googleAuth),
        const SizedBox(height: 14),
        HBTonalButton(
            label: s.t('continueFacebook'),
            icon: Icons.facebook,
            onPressed: ()=> _showComingSoonMessage(context)),
        const SizedBox(height: 14),
        HBOutlineButton(
            label: s.t('continuePhone'), icon: Icons.phone, onPressed: ()=> _showComingSoonMessage(context)),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => setState(() => _emailPane = !_emailPane),
          child: Text(s.t('orEmailLogin'), style: accentTxt),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_emailPane
              ? const SizedBox.shrink()
              : Column(
            key: const ValueKey('emailLogin'),
            children: [
              const SizedBox(height: 12),
              TextField(
                controller: emailLogin,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: s.t('email')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passLogin,
                obscureText: true,
                decoration: InputDecoration(labelText: s.t('password')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    s.t('forgotPassword'),
                    style: TextStyle(
                      color: dark ? pal.accentGold : pal.primaryDeep,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              HBPrimaryButton(
                label: s.t('login'),
                loading: _loadingLogin,
                onPressed: _loadingLogin ? null : emailLoginFn,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
            );
          },
          child: Text(
            "Terms and Conditions",
            style: TextStyle(
              color: dark ? pal.accentGold : pal.primaryDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupPanel() {
    final s = this.s;
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accentTxt = TextStyle(
      fontWeight: FontWeight.w700,
      color: dark ? pal.accentGold : pal.primaryDeep,
    );

    return Form(
      key: signupKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
              controller: nameSignup,
              validator: (v) => validate(v),
              decoration: InputDecoration(labelText: s.t('name'))),
          const SizedBox(height: 16),
          TextFormField(
              controller: emailSignup,
              validator: (v) => validate(v, email: true),
              decoration: InputDecoration(labelText: s.t('email'))),
          const SizedBox(height: 16),
          TextFormField(
            controller: passSignup,
            obscureText: _obscure,
            validator: (v) => validate(v, pass: true),
            decoration: InputDecoration(
              labelText: s.t('password'),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmSignup,
            obscureText: _obscure,
            validator: (v) => validate(v, confirm: true),
            decoration: InputDecoration(labelText: s.t('confirmPassword')),
          ),
          const SizedBox(height: 20),

          /// 🔒 Terms Checkbox with link
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value!),
                activeColor: dark ? pal.accentGold : pal.primaryDeep,
              ),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      "I agree to the ",
                      style: TextStyle(
                        fontSize: 15,
                        color: dark ? pal.accentGold : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TermsAndConditionsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Terms and Conditions",
                        style: TextStyle(
                          color: dark ? pal.accentGold : pal.primaryDeep,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// 🚫 Conditionally allow create account
          HBPrimaryButton(
            label: s.t('createAccount'),
            loading: _loadingSignup,
            onPressed: _loadingSignup
                ? null
                : () {
              if (!_acceptedTerms) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "You must accept the Terms and Conditions before creating an account.",
                      style: TextStyle(fontSize: 15),
                    ),
                    backgroundColor:
                    dark ? Colors.red[300] : Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              /// ✅ If accepted, proceed with signup
              signupFn();
            },
          ),
        ],
      ),
    );
  }
}


void _showComingSoonMessage(BuildContext context) {
  final pal = Theme.of(context).extension<AppColors>()!;
  final dark = Theme.of(context).brightness == Brightness.dark;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "This feature will be available in an upcoming update.",
        style: TextStyle(
          fontSize: 15,
          color: dark ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: dark ? pal.accentGold : pal.primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: 3),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
  );
}

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: dark ? Colors.white70 : Colors.black87,
    );
    final headerStyle = textStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: dark ? pal.accentGold : pal.primaryDeep,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Terms and Conditions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome to HomeBlend", style: headerStyle),
              const SizedBox(height: 10),
              Text(
                "These Terms and Conditions govern your use of the HomeBlend mobile application and services. By creating an account or using any part of the app, you agree to the following:",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("1. Purpose", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "HomeBlend is a furniture and home décor platform designed to help users discover, view, and purchase curated items for their home. We offer both light and dark themes to suit your comfort.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("2. Account & Privacy", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "You must provide accurate information during signup. Your data is encrypted and never sold. HomeBlend respects your privacy and complies with applicable data protection laws.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("3. Purchases", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "All purchases made through HomeBlend are final. Refunds are only available for damaged or defective items, reported within 48 hours of delivery.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("4. User Conduct", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "You agree not to misuse the app or upload harmful, offensive, or misleading content. Violating these terms may lead to suspension or deletion of your account.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("5. App Updates", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "We regularly update the HomeBlend app to enhance your experience. It's your responsibility to install updates when available.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("6. Liability", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "HomeBlend is not liable for any losses resulting from delays, shipping errors, or third-party services.",
                style: textStyle,
              ),
              const SizedBox(height: 20),

              Text("7. Acceptance", style: headerStyle),
              const SizedBox(height: 6),
              Text(
                "By using HomeBlend, you agree to these terms. If you do not agree, please discontinue using the app.",
                style: textStyle,
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactUsScreen()),
                  );
                },
                icon: Icon(Icons.contact_mail, color: dark ? pal.accentGold : pal.primaryDeep),
                label: Text(
                  "Contact Us",
                  style: TextStyle(
                    color: dark ? pal.accentGold : pal.primaryDeep,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Last updated: July 2025",
                style: textStyle.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: dark ? pal.accentGold : pal.primaryDeep,
    );
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white70 : Colors.black87,
    );
    final contentStyle = TextStyle(
      fontSize: 16,
      color: dark ? Colors.white60 : Colors.black54,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Contact Us")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("We’d love to hear from you!", style: titleStyle),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone, color: dark ? pal.accentGold : pal.primaryDeep),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone", style: labelStyle),
                    const SizedBox(height: 4),
                    Text("+20 122 287 8031", style: contentStyle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.email, color: dark ? pal.accentGold : pal.primaryDeep),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email", style: labelStyle),
                    const SizedBox(height: 4),
                    Text("home.blend11@gmail.com", style: contentStyle),
                    const SizedBox(height: 2),
                    Text("ceo@home-blend.com", style: contentStyle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "Our team will respond within 24-48 hours during business days.",
              style: contentStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final TabController controller;
  const _ModeTabs({required this.controller});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          color: pal.surfaceAlt,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ]),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: pal.cardLightBrown,
          borderRadius: BorderRadius.circular(40),
        ),
        labelColor: dark ? Colors.black : pal.primaryDeep,
        unselectedLabelColor:
        (dark ? Colors.white : pal.primaryDeep).withOpacity(.65),
        labelStyle:
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
      ),
    );
  }
}

/// =======================================================================
/// MAIN SHELL (added Favorites tab)
/// =======================================================================
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    CatalogScreen(),
    FavoritesScreen(),
    CartScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final s = S.of(context);
    return Scaffold(
      body: IndexedStack(index: index, children: pages),

      /* ─────────────  TWO BUBBLES WHEN  index == 0  ───────────── */
      floatingActionButton: index == 0
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ――― Existing Scan‑QR bubble ―――
          FloatingActionButton.extended(
            heroTag: 'scanQR',
            backgroundColor:
            Theme.of(context).extension<AppColors>()!.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              s.t('scanQr'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScanScreen()),
              );
            },
          ),
        ],
      )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), label: s.t('home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chair_outlined), label: s.t('catalog')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border), label: s.t('favorites')),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                Positioned(
                  right: -6,
                  top: -4,
                  child: _Badge(
                    show: state.cart.isNotEmpty,
                    child: Text(
                      '${state.cart.fold<int>(0, (s, l) => s + l.qty)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            label: s.t('cart'),
          ),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline), label: s.t('profile')),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final bool show;
  final Widget child;
  const _Badge({required this.show, required this.child});
  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final pal = Theme.of(context).extension<AppColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: pal.primary, borderRadius: BorderRadius.circular(20)),
      child:
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), child: child),
    );
  }
}

/// =======================================================================
/// HOME (unchanged except label)
/// =======================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    state.loadProductsIfNeeded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final s = S.of(context);
    final state = AppStateScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            color: pal.bg,
            child: Text('HOMEBLEND',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : pal.primaryDeep,
                )),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _HomeStat(
                          icon: Icons.view_module_rounded,
                          label: s.t('products'),
                          value: '${state.products.length}'),
                      _HomeStat(
                          icon: Icons.category_outlined,
                          label: s.t('categories'),
                          value: '${state.categories.length}'),
                      _HomeStat(
                          icon: Icons.shopping_bag_outlined,
                          label: s.t('cartItems'),
                          value:
                          '${state.cart.fold<int>(0, (s, l) => s + l.qty)}'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  HBPrimaryButton(
                    label: s.t('goToCatalog'),
                    icon: Icons.chair_alt_outlined,
                    onPressed: () {
                      final shell =
                      context.findAncestorStateOfType<_MainShellState>();
                      shell?.setState(() => shell.index = 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HomeStat(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: dark ? pal.cardLightBrown : pal.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: dark ? Colors.white : pal.primaryDeep),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w900,
                color: dark ? Colors.white : pal.primaryDeep,
              )),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: dark
                    ? Colors.white.withOpacity(.85)
                    : pal.primaryDeep.withOpacity(.70),
              )),
        ],
      ),
    );
  }
}

/// =======================================================================
/// CATALOG  (selection fix uses setState on header actions)
/// =======================================================================
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Timer? _debounce;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    state.loadProductsIfNeeded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _onSearchChanged(String v, AppState st) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 140), () {
      if (mounted) st.setSearch(v);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  int _calcCols(double w) {
    if (w.isNaN || w <= 0) return 2;
    if (w >= 1400) return 6;
    if (w >= 1150) return 5;
    if (w >= 900) return 4;
    if (w >= 650) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final prodsSnapshot = List<Product>.unmodifiable(state.products);
    final s = S.of(context);
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pal = Theme.of(context).extension<AppColors>()!;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyCatalogHeader(
            selectedCategory: state.selectedCategory,
            categoriesSignature: state.categories.join('|').hashCode,
            safeTop: safeTop,
            builder: (ctx, topPad, overlap) {
              final st = AppStateScope.of(ctx);
              return Container(
                color: dark ? Colors.black : pal.bg,
                padding: EdgeInsets.only(top: topPad),
                child: Column(
                  children: [
                    // Search Row
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  _onSearchChanged(v, st),
                              style: TextStyle(
                                color: dark
                                    ? Colors.white
                                    : pal.primaryDeep,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: s.t('searchHint'),
                                hintStyle: TextStyle(
                                  color: dark
                                      ? Colors.white.withOpacity(.55)
                                      : pal.primaryDeep
                                      .withOpacity(.55),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(Icons.search,
                                    color: dark
                                        ? Colors.white70
                                        : pal.primaryDeep
                                        .withOpacity(.75)),
                              ),
                            ),
                          ),
                          //const SizedBox(width: 12),
                          // Container(
                          //   height: 50,
                          //   width: 50,
                          //   decoration: BoxDecoration(
                          //     color: pal.surfaceAlt,
                          //     borderRadius: BorderRadius.circular(18),
                          //   ),
                          //   // child: Icon(Icons.tune,
                          //   //     color: dark
                          //   //         ? Colors.black38
                          //   //         : pal.primaryDeep),
                          // ),
                        ],
                      ),
                    ),
                    // Category Chips
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                        itemCount: st.categories.length,
                        itemBuilder: (_, i) {
                          final cat = st.categories[i];
                          final sel = cat == st.selectedCategory;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: sel,
                            onSelected: (_) {
                              st.setCategory(cat);
                              // Force rebuild header for immediate visual
                              setState(() {});
                            },
                            showCheckmark: true,
                            checkmarkColor: Colors.white,
                            selectedColor: pal.primary,
                            backgroundColor: dark
                                ? Colors.white.withOpacity(.08)
                                : pal.surfaceAlt,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : (dark
                                  ? Colors.white
                                  .withOpacity(.85)
                                  : pal.primaryDeep),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: BorderSide(
                                color: sel
                                    ? pal.primary.withOpacity(0)
                                    : pal.primary.withOpacity(.40),
                                width: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          sliver: SafeSliverGrid(
            products: prodsSnapshot,
            calcCols: _calcCols,
            emptyLabel: s.t('noResults'),
          ),
        ),
      ],
    );
  }
}

class _StickyCatalogHeader extends SliverPersistentHeaderDelegate {
  final String selectedCategory;
  final int categoriesSignature;
  final double safeTop;
  final Widget Function(BuildContext context, double safeTop, bool overlaps)
  builder;

  static const double _searchSectionHeight = 66;
  static const double _chipsHeight = 60;
  static const double _gapBelowChips = 4;

  late final double _totalHeight =
      safeTop + _searchSectionHeight + _chipsHeight + _gapBelowChips;

  _StickyCatalogHeader({
    required this.selectedCategory,
    required this.categoriesSignature,
    required this.safeTop,
    required this.builder,
  });

  @override
  double get minExtent => _totalHeight;
  @override
  double get maxExtent => _totalHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: _totalHeight,
      child: builder(context, safeTop, overlapsContent),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCatalogHeader old) {
    return selectedCategory != old.selectedCategory ||
        categoriesSignature != old.categoriesSignature ||
        safeTop != old.safeTop;
  }
}

class SafeSliverGrid extends StatelessWidget {
  final List<Product> products;
  final int Function(double width) calcCols;
  final String emptyLabel;
  const SafeSliverGrid({
    super.key,
    required this.products,
    required this.calcCols,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int cols;
    try {
      cols = max(1, calcCols(width));
    } catch (_) {
      cols = 2;
    }
    if (products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    try {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
              (c, i) {
            if (i < 0 || i >= products.length) return const SizedBox.shrink();
            return ProductCard(product: products[i]);
          },
          childCount: products.length,
        ),
      );
    } catch (e, st) {
      debugPrint('SAFE GRID ERROR: $e\n$st');
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Error building grid',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }
}

/// =======================================================================
/// PRODUCT CARD
/// =======================================================================
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({required this.product, super.key});
  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool favLocal = false;

  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final p = widget.product;
    final state = AppStateScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isFav = state.isFav(p.id);
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(product: p),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child))),
      child: Ink(
        decoration: BoxDecoration(
            color: dark ? pal.cardLightBrown : pal.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ]),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                      child: Hero(
                        tag: p.id,
                        child: Image.network(p.images.isNotEmpty
                            ? p.images.first
                            : 'https://via.placeholder.com/700',
                            fit: BoxFit.cover, errorBuilder:
                                (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            )),
                      ),
                    ),
                  ),
                  //Positioned(top: 8, left: 8, child: _RatingBadge(rating: p.rating)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        state.toggleFav(p);
                        setState(() => favLocal = !favLocal);
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        scale: (isFav) ? 1.08 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dark
                                ? pal.cardLightBrown.withOpacity(.8)
                                : pal.cardLightBrown.withOpacity(.8),
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: Colors.white.withOpacity(.15)),
                          ),
                          child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color:
                              dark ? pal.primaryDeep : pal.primaryDeep),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : pal.primaryDeep)),
                  const SizedBox(height: 2),
                  Text('EGP ${p.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : pal.primaryDeep)),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => state.addToCart(p),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: dark ? pal.primaryDeep : pal.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add,
                            size: 22, color: Colors.white.withOpacity(.95)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star, size: 14, color: Colors.amber),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }
}

/// =======================================================================
/// PRODUCT DETAIL (added Code + Category + Variants table remains)
/// =======================================================================
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final s = S.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateScope.of(context);

    final line = state.cart.firstWhere(
            (l) => l.product.id == product.id && l.variant == 'Default',
        orElse: () => CartLine(product: product, qty: 0));

    // Build variants table if multi
    Widget buildVariants() {
      if (product.allPrices.length <= 1) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 24, 18, 12),
        decoration: BoxDecoration(
          color: dark ? pal.surfaceAlt : pal.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [
                    pal.primaryDeep,
                    pal.primary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, color: Colors.white.withOpacity(.95)),
                  const SizedBox(width: 8),
                  Text(s.t('variants'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: Colors.white, fontWeight: FontWeight.w800))
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: List.generate(product.allPrices.length, (i) {
                  final vDesc = product.variantDescriptions.length > i
                      ? product.variantDescriptions[i]
                      : 'Option ${i + 1}';
                  final price = product.allPrices[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vDesc,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? Colors.white
                                  : pal.primaryDeep,
                            ),
                          ),
                        ),
                        Text('EGP ${price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                fontWeight: FontWeight.w700,
                                color: pal.accentGold)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => state.addToCart(product, variant: vDesc),
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: dark
                                  ? pal.primaryDeep
                                  : pal.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add,
                                size: 22, color: Colors.white.withOpacity(.95)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
              product.missing
                  ? s.t('notFound')
                  : product.name.split(' ').take(3).join(' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 140),
        children: [
          if (!product.missing)
            SizedBox(
              height: MediaQuery.of(context).size.width, // keep square aspect
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: product.images.isNotEmpty ? product.images.length : 1,
                    controller: PageController(viewportFraction: 1),
                    itemBuilder: (_, i) => Hero(
                      tag: '${product.id}_$i',
                      child: Image.network(
                        product.images.isNotEmpty
                            ? product.images[i]
                            : 'https://via.placeholder.com/700',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // tiny dots indicator
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 12,
                      child: StatefulBuilder(
                        builder: (ctx, setDot) {
                          // keep local page index
                          final controller = PageController();
                          controller.addListener(() => setDot(() {}));
                          final curr = controller.hasClients ? controller.page?.round() ?? 0 : 0;
                          return Row(
                            children: List.generate(product.images.length, (i) {
                              final selected = i == curr;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 7,
                                width: selected ? 18 : 7,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Theme.of(context).extension<AppColors>()!.accentGold
                                      : Colors.white70,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          // Name
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
            child: Text(product.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : pal.primaryDeep)),
          ),
          // Price
          if (!product.missing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('EGP ${product.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : pal.primaryDeep)),
            ),
          // Code
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Text(
              '${s.t('code')}: ${product.linkCode.isNotEmpty ? product.linkCode : product.id}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : pal.primaryDeep,
              ),
            ),
          ),
          // Category
          if (product.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Text(
                '${s.t('category')}: ${product.category}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? Colors.white.withOpacity(.75)
                      : pal.primaryDeep.withOpacity(.70),
                ),
              ),
            ),
          // Size
          if (product.height.isNotEmpty || product.width.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Text(
                '${product.height.isNotEmpty ? product.height : '--'} × ${product.width.isNotEmpty ? product.width : '--'}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? Colors.white.withOpacity(.75)
                      : pal.primaryDeep.withOpacity(.70),
                ),
              ),
            ),
          // Description (if single)
          if (product.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: dark
                      ? Colors.white.withOpacity(.82)
                      : pal.primaryDeep.withOpacity(.9),
                ),
              ),
            ),
          // Variants (multi)
          const SizedBox(height: 10),
          if (product.supportsAR && product.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: HBPrimaryButton(
                label: 'View AR',
                icon: Icons.view_in_ar,
                // onPressed: () => Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => ARViewScreen(product: product)),
                // ),
                onPressed: ()=> _showComingSoonMessage(context)
              ),
            ),
          buildVariants(),
        ],
      ),
      bottomSheet: product.missing
          ? null
          : Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        decoration: BoxDecoration(
            color: dark ? Colors.black : pal.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.18),
                  blurRadius: 26,
                  offset: const Offset(0, -6))
            ]),
        child: Row(
          children: [
            _QtyControl(
              qty: line.qty,
              onAdd: () => state.addToCart(product),
              onRemove: () =>
                  state.decrease(product),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: HBPrimaryButton(
                label: line.qty == 0
                    ? s.t('addToCart')
                    : s.t('addMore'),
                onPressed: () => state.addToCart(product),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyControl(
      {required this.qty, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pal.surfaceAlt,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: pal.primary.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundIcon(icon: Icons.remove, onTap: qty > 0 ? onRemove : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$qty',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: dark ? Colors.white : pal.primaryDeep)),
          ),
          _RoundIcon(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIcon({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: enabled
            ? (dark ? Colors.white : pal.primaryDeep)
            : (dark
            ? Colors.white.withOpacity(.30)
            : pal.primaryDeep.withOpacity(.30))),
      ),
    );
  }
}

/// =======================================================================
/// CART
/// =======================================================================
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s   = S.of(context);
    final pal = Theme.of(context).extension<AppColors>()!;
    final state = AppStateScope.of(context);
    final dark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('cart')),
        actions: [
          if (state.cart.isNotEmpty)
            TextButton(
              onPressed: state.clearCart,
              child: Text(s.t('clear'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? pal.accentGold : pal.primaryDeep)),
            ),
        ],
      ),
      body: state.cart.isEmpty
          ? Center(
          child: Text(s.t('cartEmpty'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                  dark ? Colors.white : pal.primaryDeep)))
          : ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 150),
        children: [
          ...state.cart.map((l) => _CartLine(line: l)),
          const SizedBox(height: 12),
          const Divider(),
          _SummaryRow(label: s.t('subtotal'), value: state.subtotal),
          _SummaryRow(label: s.t('delivery'), value: state.delivery),
          const Divider(),
          _SummaryRow(
              label: s.t('total'), value: state.total, bold: true),
        ],
      ),
      bottomSheet: state.cart.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
        decoration: BoxDecoration(
            color: dark ? Colors.black : pal.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.22),
                  blurRadius: 28,
                  offset: const Offset(0, -8))
            ]),
        child: SafeArea(
          top: false,
          child: HBPrimaryButton(
            label:
            '${s.t('checkout')} • EGP ${state.total.toStringAsFixed(0)}',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(s.t('checkout')),
                content: Text(s.t('checkoutMock')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartLine line;
  const _CartLine({required this.line});
  @override
  Widget build(BuildContext context) {
    final pal   = Theme.of(context).extension<AppColors>()!;
    final state = AppStateScope.of(context);                // ✱ NEW
    final dark  = Theme.of(context).brightness == Brightness.dark;
    final price = state.priceOf(line);                      // ✱ NEW

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      height: 115,
      decoration: BoxDecoration(
          color: dark ? pal.cardLightBrown : pal.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(30)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                line.product.images.isNotEmpty
                    ? line.product.images.first
                    : 'https://via.placeholder.com/300',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color:
                          dark ? Colors.white : pal.primaryDeep)),
                  const SizedBox(height: 4),
                  if (line.variant != 'Default')
                    Text(line.variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: dark
                                ? Colors.white.withOpacity(.75)
                                : pal.primaryDeep.withOpacity(.65))),
                  const Spacer(),
                  Text('EGP ${price.toStringAsFixed(0)}',          // ✱ NEW
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                          dark ? Colors.white : pal.primaryDeep)),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundIcon(
                  icon: Icons.add,
                  onTap: () => state.addToCart(line.product,
                      variant: line.variant)),
              Text('${line.qty}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color:
                      dark ? Colors.white : pal.primaryDeep)),
              _RoundIcon(
                  icon: Icons.remove,
                  onTap: () => state.decrease(line.product,
                      variant: line.variant)),
            ],
          ),
          IconButton(
              onPressed: () =>
                  state.remove(line.product, variant: line.variant),
              icon: Icon(Icons.close,
                  color: dark
                      ? Colors.white.withOpacity(.8)
                      : pal.primaryDeep.withOpacity(.85))),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = bold
        ? Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w900,
      color: dark ? Colors.white : pal.primaryDeep,
    )
        : Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white : pal.primaryDeep,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text('EGP ${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

/// =======================================================================
/// FAVORITES
/// =======================================================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final s = S.of(context);
    final favProducts =
    state.products.where((p) => state.isFav(p.id)).toList();
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('favorites'))),
      body: favProducts.isEmpty
          ? Center(
          child: Text('No Favourites Yet',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : pal.primaryDeep)))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: .62),
        itemCount: favProducts.length,
        itemBuilder: (_, i) => ProductCard(product: favProducts[i]),
      ),
    );
  }
}

/// =======================================================================
/// PROFILE
/// =======================================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final state = AppStateScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final display = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'User');
    final pretty = display.isEmpty
        ? 'User'
        : display[0].toUpperCase() + display.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: pal.primary,
            child: Text(
              pretty[0],
              style:
              Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(pretty,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : pal.primaryDeep)),
          const SizedBox(height: 6),
          if (user?.email != null)
            Text(user!.email!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: dark
                        ? Colors.white.withOpacity(.70)
                        : pal.primaryDeep.withOpacity(.70))),
          const SizedBox(height: 30),
          HBPrimaryButton(
            label:
            '${s.t('cartItems')}: ${state.cart.fold<int>(0, (s, l) => s + l.qty)}',
            icon: Icons.shopping_bag_outlined,
            onPressed: () {
              final shell =
              context.findAncestorStateOfType<_MainShellState>();
              shell?.setState(() => shell.index = 3);
            },
          ),
          const SizedBox(height: 16),
          HBTonalButton(
            label: s.t('langToggle'),
            icon: Icons.language,
            onPressed: state.localeChanger,
          ),
          const SizedBox(height: 16.5),
          // TextButton.icon(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => ContactUsScreen()),
          //     );
          //   },
          //   icon: Icon(Icons.contact_mail, color: dark ? pal.accentGold : pal.primaryDeep),
          //   label: Text(
          //     "Contact Us",
          //     style: TextStyle(
          //       color: dark ? pal.accentGold : pal.primaryDeep,
          //       fontWeight: FontWeight.w600,
          //       fontSize: 16,
          //     ),
          //   ),
          // ),
          // HBOutlineButton(
          //   label: "Contact Us",
          //   icon: Icons.contact_mail,
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => ContactUsScreen()),
          //     );
          //   },
          // ),
          //const SizedBox(height: 16),
          HBOutlineButton(
            label: '${s.t('darkMode')}: ${state.dark.value ? 'On' : 'Off'}',
            icon: state.dark.value
                ? Icons.dark_mode
                : Icons.dark_mode_outlined,
            onPressed: () => state.dark.value = !state.dark.value,
          ),
          const SizedBox(height: 16.5),
          HBOutlineButton(
            label: s.t('logout'),
            icon: Icons.logout,
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          // const SizedBox(height: 16.5),
          // Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(30),
          //     border: Border.all(
          //       color: dark ? pal.accentGold : pal.primaryDeep,
          //       width: 1.5,
          //     ),
          //   ),
          //   child: TextButton.icon(
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => ContactUsScreen()),
          //       );
          //     },
          //     icon: Icon(
          //       Icons.contact_mail,
          //       color: dark ? pal.accentGold : pal.primaryDeep,
          //     ),
          //     label: Text(
          //       "Contact Us",
          //       style: TextStyle(
          //         color: dark ? pal.accentGold : pal.primaryDeep,
          //         fontWeight: FontWeight.w600,
          //         fontSize: 16,
          //       ),
          //     ),
          //     style: TextButton.styleFrom(
          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(30),
          //       ),
          //       foregroundColor: Colors.transparent,
          //       backgroundColor: Colors.transparent,
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}

/// =======================================================================
/// QR SCAN (using mobile_scanner)
/// =======================================================================
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});
  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final controller = MobileScannerController();
  String? message;
  bool _handled = false;

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final codes = cap.barcodes.map((b) => b.rawValue ?? '').where((s) => s.isNotEmpty);
    if (codes.isEmpty) return;
    final code = codes.first.trim();
    final state = AppStateScope.of(context);
    final p = state.find(code);
    if (p.missing) {
      setState(() => message = 'Not found: $code');
    } else {
      _handled = true;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p)));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('qrTitle'))),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
              ),
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(message!,
                  style: TextStyle(
                      color: pal.error, fontWeight: FontWeight.w600)),
            ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: HBPrimaryButton(
              label: s.t('close'),
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================================
/// REUSABLE BUTTONS (unchanged)
/// =======================================================================
abstract class _HBBaseButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;
  const _HBBaseButton(
      {super.key,
        required this.label,
        this.icon,
        this.loading = false,
        this.onPressed});
  Widget buildChild(Color txtColor) {
    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
          strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(txtColor)),
    );
    if (icon == null) {
      return loading ? spinner : Text(label, textAlign: TextAlign.center);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!loading) Icon(icon, size: 20),
        if (!loading) const SizedBox(width: 8),
        loading ? spinner : Text(label),
      ],
    );
  }
}

class HBPrimaryButton extends _HBBaseButton {
  const HBPrimaryButton(
      {super.key,
        required super.label,
        super.icon,
        super.loading = false,
        super.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: loading ? null : onPressed, child: buildChild(Colors.white));
  }
}

class HBTonalButton extends _HBBaseButton {
  const HBTonalButton(
      {super.key,
        required super.label,
        super.icon,
        super.onPressed,
        super.loading = false});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    return FilledButton(
        onPressed: loading ? null : onPressed,
        child: buildChild(pal.primaryDeep));
  }
}

class HBOutlineButton extends _HBBaseButton {
  const HBOutlineButton(
      {super.key,
        required super.label,
        super.icon,
        super.onPressed,
        super.loading = false});
  @override
  Widget build(BuildContext context) {
    final pal = Theme.of(context).extension<AppColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: buildChild(dark ? Colors.white : pal.primaryDeep));
  }
}

/// =======================================================================
/// UTIL
/// =======================================================================
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 50)
      ..quadraticBezierTo(
          size.width * 0.5, size.height, size.width, size.height - 60)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// place near the bottom of main.dart

// class ARViewScreen extends StatefulWidget {
//   final Product product;
//   const ARViewScreen({super.key, required this.product});
//   @override
//   State<ARViewScreen> createState() => _ARViewScreenState();
// }
//
// class _ARViewScreenState extends State<ARViewScreen> {
//   late final CameraController _cam;
//   bool _ready = false;
//
//   Offset  _offset   = Offset.zero;
//   double  _scale    = 1.0;
//   double  _rotation = 0.0;
//   bool    _pinned   = false;
//   bool    _flipped  = false;
//
//   double? _startScale;
//   double? _startRotation;
//
//   static const _minScale = 0.3;
//   static const _maxScale = 3.0;
//   static const _rotationFactor = 0.4;
//
//   @override
//   void initState() {
//     super.initState();
//     _cam = CameraController(
//       cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
//       ResolutionPreset.medium,
//       enableAudio: false,
//     )..initialize().then((_) => setState(() => _ready = true));
//   }
//
//   @override
//   void dispose() {
//     _cam.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final pal  = Theme.of(context).extension<AppColors>()!;
//     final size = MediaQuery.of(context).size;
//
//     if (!_pinned) {
//       _offset = Offset(size.width / 2, size.height / 2);   // follow‑camera mode
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('View AR')),
//       body: !_ready
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//         fit: StackFit.expand,
//         children: [
//           CameraPreview(_cam),
//           Container(color: Colors.black.withOpacity(.05)),
//
//           // ---------- product with gestures ----------
//           GestureDetector(
//             onScaleStart: (d) {
//               _startScale    = _scale;       // baselines for smoother zoom
//               _startRotation = _rotation;
//             },
//             onScaleUpdate: (d) {
//               if (!_pinned) return;          // ignore moves while following
//               setState(() {
//                 // ⬅️ translation: back to incremental delta
//                 _offset += d.focalPointDelta;
//
//                 // zoom + clamp
//                 _scale = (_startScale! * d.scale)
//                     .clamp(_minScale, _maxScale);
//
//                 // rotation with damping
//                 _rotation =
//                     _startRotation! + d.rotation * _rotationFactor;
//               });
//             },
//             onDoubleTap: () => setState(() => _pinned = !_pinned),
//             child: Transform(
//               alignment: Alignment.center,
//               transform: Matrix4.identity()
//                 ..translate(
//                   _offset.dx - size.width / 2,
//                   _offset.dy - size.height / 2,
//                 )
//                 ..rotateZ(_rotation)
//                 ..scale(_flipped ? -_scale : _scale, _scale),
//               child: Image.network(
//                 widget.product.images.first,
//                 width: size.width * .75,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//
//           // ---------- flip & close buttons ----------
//           Positioned(
//             left: 20,
//             bottom: 40,
//             child: FloatingActionButton(
//               heroTag: 'flip',
//               mini: true,
//               backgroundColor: pal.primary,
//               child: const Icon(Icons.flip),
//               onPressed: () => setState(() => _flipped = !_flipped),
//             ),
//           ),
//           Positioned(
//             right: 20,
//             bottom: 40,
//             child: FloatingActionButton.extended(
//               heroTag: 'close',
//               backgroundColor: pal.primary,
//               icon: const Icon(Icons.close),
//               label: const Text('Close'),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class ARViewScreen extends StatefulWidget {
  final Product product;
  const ARViewScreen({Key? key, required this.product}) : super(key: key);
  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  late ARSessionManager _sessionManager;
  late ARObjectManager  _objectManager;
  late ARAnchorManager  _anchorManager;
  ARNode?               _modelNode;

  @override
  void dispose() {
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View AR')),
      body: ARView(
        onARViewCreated: _onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontal,
      ),
    );
  }

  void _onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) {
    _sessionManager = sessionManager;
    _objectManager  = objectManager;
    _anchorManager  = anchorManager;

    _sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "assets/plane.png",
      showWorldOrigin: false,
      handleTaps: true,
    );
    _objectManager.onInitialize();

    // 1) when user taps a plane...
    _sessionManager.onPlaneOrPointTap = _onPlaneTap;

    // 2) when user finishes pan/rotate
    _objectManager.onPanEnd      = _onPanEnd;
    _objectManager.onRotationEnd = _onRotationEnd;
  }

  Future<void> _onPlaneTap(List<ARHitTestResult> hits) async {
    if (_modelNode != null) return;

    final hit = hits.firstWhere(
          (h) => h.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    // create & add a plane anchor
    final planeAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    await _anchorManager.addAnchor(planeAnchor);

    // create the 3D node
    final rotationMatrix = hit.worldTransform.getRotation();
    final quaternion = Quaternion.fromRotation(rotationMatrix);

// create the 3D node
    final node = ARNode(
      type: NodeType.webGLB,
      uri: widget.product.drive.first,
      scale: Vector3(1, 1, 1),
      position: hit.worldTransform.getTranslation(),
      rotation: Vector4(quaternion.x, quaternion.y, quaternion.z, quaternion.w),
    );

    // attach it
    final added = await _objectManager.addNode(node, planeAnchor: planeAnchor);
    if (added == true) {
      _modelNode = node;
    }
  }

  void _onPanEnd(String nodeName, Matrix4 newTransform) {
    if (_modelNode?.name != nodeName) return;
    _modelNode!.transformNotifier.value = newTransform;
  }

  void _onRotationEnd(String nodeName, Matrix4 newTransform) {
    if (_modelNode?.name != nodeName) return;
    _modelNode!.transformNotifier.value = newTransform;
  }
}