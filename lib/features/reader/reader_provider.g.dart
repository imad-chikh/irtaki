// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$versesForPageHash() => r'6d0b09afba4f1ac3cdcb145f05a9b1ec5d2cdda8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [versesForPage].
@ProviderFor(versesForPage)
const versesForPageProvider = VersesForPageFamily();

/// See also [versesForPage].
class VersesForPageFamily extends Family<AsyncValue<List<Verse>>> {
  /// See also [versesForPage].
  const VersesForPageFamily();

  /// See also [versesForPage].
  VersesForPageProvider call(int page) {
    return VersesForPageProvider(page);
  }

  @override
  VersesForPageProvider getProviderOverride(
    covariant VersesForPageProvider provider,
  ) {
    return call(provider.page);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'versesForPageProvider';
}

/// See also [versesForPage].
class VersesForPageProvider extends AutoDisposeFutureProvider<List<Verse>> {
  /// See also [versesForPage].
  VersesForPageProvider(int page)
    : this._internal(
        (ref) => versesForPage(ref as VersesForPageRef, page),
        from: versesForPageProvider,
        name: r'versesForPageProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$versesForPageHash,
        dependencies: VersesForPageFamily._dependencies,
        allTransitiveDependencies:
            VersesForPageFamily._allTransitiveDependencies,
        page: page,
      );

  VersesForPageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.page,
  }) : super.internal();

  final int page;

  @override
  Override overrideWith(
    FutureOr<List<Verse>> Function(VersesForPageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VersesForPageProvider._internal(
        (ref) => create(ref as VersesForPageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Verse>> createElement() {
    return _VersesForPageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VersesForPageProvider && other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VersesForPageRef on AutoDisposeFutureProviderRef<List<Verse>> {
  /// The parameter `page` of this provider.
  int get page;
}

class _VersesForPageProviderElement
    extends AutoDisposeFutureProviderElement<List<Verse>>
    with VersesForPageRef {
  _VersesForPageProviderElement(super.provider);

  @override
  int get page => (origin as VersesForPageProvider).page;
}

String _$totalPagesHash() => r'8c2b0dd231f7e19b6c88b47ac5b43ea84255d956';

/// See also [totalPages].
@ProviderFor(totalPages)
final totalPagesProvider = AutoDisposeFutureProvider<int>.internal(
  totalPages,
  name: r'totalPagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalPagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalPagesRef = AutoDisposeFutureProviderRef<int>;
String _$currentPageNotifierHash() =>
    r'489e8d1bb70f98c9a105dbea307589d0459137c5';

abstract class _$CurrentPageNotifier extends BuildlessAutoDisposeNotifier<int> {
  late final int initialPage;

  int build(int initialPage);
}

/// See also [CurrentPageNotifier].
@ProviderFor(CurrentPageNotifier)
const currentPageNotifierProvider = CurrentPageNotifierFamily();

/// See also [CurrentPageNotifier].
class CurrentPageNotifierFamily extends Family<int> {
  /// See also [CurrentPageNotifier].
  const CurrentPageNotifierFamily();

  /// See also [CurrentPageNotifier].
  CurrentPageNotifierProvider call(int initialPage) {
    return CurrentPageNotifierProvider(initialPage);
  }

  @override
  CurrentPageNotifierProvider getProviderOverride(
    covariant CurrentPageNotifierProvider provider,
  ) {
    return call(provider.initialPage);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentPageNotifierProvider';
}

/// See also [CurrentPageNotifier].
class CurrentPageNotifierProvider
    extends AutoDisposeNotifierProviderImpl<CurrentPageNotifier, int> {
  /// See also [CurrentPageNotifier].
  CurrentPageNotifierProvider(int initialPage)
    : this._internal(
        () => CurrentPageNotifier()..initialPage = initialPage,
        from: currentPageNotifierProvider,
        name: r'currentPageNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentPageNotifierHash,
        dependencies: CurrentPageNotifierFamily._dependencies,
        allTransitiveDependencies:
            CurrentPageNotifierFamily._allTransitiveDependencies,
        initialPage: initialPage,
      );

  CurrentPageNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialPage,
  }) : super.internal();

  final int initialPage;

  @override
  int runNotifierBuild(covariant CurrentPageNotifier notifier) {
    return notifier.build(initialPage);
  }

  @override
  Override overrideWith(CurrentPageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CurrentPageNotifierProvider._internal(
        () => create()..initialPage = initialPage,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialPage: initialPage,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CurrentPageNotifier, int> createElement() {
    return _CurrentPageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentPageNotifierProvider &&
        other.initialPage == initialPage;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialPage.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentPageNotifierRef on AutoDisposeNotifierProviderRef<int> {
  /// The parameter `initialPage` of this provider.
  int get initialPage;
}

class _CurrentPageNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<CurrentPageNotifier, int>
    with CurrentPageNotifierRef {
  _CurrentPageNotifierProviderElement(super.provider);

  @override
  int get initialPage => (origin as CurrentPageNotifierProvider).initialPage;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
