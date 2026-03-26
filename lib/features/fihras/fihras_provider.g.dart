// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fihras_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSurahsHash() => r'985b4a56945959c84ac39cf85a55eb09ae65270e';

/// See also [allSurahs].
@ProviderFor(allSurahs)
final allSurahsProvider = AutoDisposeFutureProvider<List<Surah>>.internal(
  allSurahs,
  name: r'allSurahsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allSurahsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSurahsRef = AutoDisposeFutureProviderRef<List<Surah>>;
String _$filteredSurahsHash() => r'a9b96e284d53fbe78788ecbbba83582ca7f20bdc';

/// See also [filteredSurahs].
@ProviderFor(filteredSurahs)
final filteredSurahsProvider = AutoDisposeFutureProvider<List<Surah>>.internal(
  filteredSurahs,
  name: r'filteredSurahsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredSurahsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredSurahsRef = AutoDisposeFutureProviderRef<List<Surah>>;
String _$searchQueryHash() => r'4a81f4981a852377cacaaef0daea5da3374edbaf';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
