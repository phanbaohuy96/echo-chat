import '../../common/constants.dart';
import '../entity/pagination.dart';

/// A use case for listing data with offset-based pagination.
///
/// This class manages pagination state and data fetching for list views.
///
/// Type parameters:
/// - [T]: The type of items in the list
/// - [P]: The type of optional parameters for filtering/querying
class ListingUseCase<T, P> {
  /// Callback function to fetch paginated data
  final Future<List<T>> Function(int offset, int limit, int page, [P? param])
  _getPaginationData;

  /// Current pagination state
  late var _pagination = Pagination(limit: fetchLimit);

  /// Cached list of fetched items
  final _data = <T>[];

  /// Number of items to fetch per request
  final int _fetchLimit;

  /// Gets the current fetch limit
  int get fetchLimit => _fetchLimit;

  /// Creates a [ListingUseCase] with the specified data fetcher and optional
  /// fetch limit.
  ///
  /// Parameters:
  /// - [_getPaginationData]: Function to fetch paginated data
  /// - [_fetchLimit]: Number of items per page
  ///   (default: [PaginationConstant.lowLimit])
  ListingUseCase(
    this._getPaginationData, [
    this._fetchLimit = PaginationConstant.lowLimit,
  ]);

  /// Gets the current pagination state
  Pagination get pagination => _pagination;

  /// Gets the cached data
  List<T> get data => _data;

  /// Fetches the initial data, resetting pagination state.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of fetched items
  Future<List<T>> getData([P? param]) async {
    _pagination = Pagination(limit: fetchLimit);
    _data.clear();
    return _getData(param);
  }

  /// Loads more data using the current pagination state.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of newly fetched items
  Future<List<T>> loadMoreData([P? param]) {
    return _getData(param);
  }

  /// Internal method to fetch data and update pagination state.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of fetched items
  Future<List<T>> _getData([P? param]) async {
    final response = await _getPaginationData(
      _pagination.nextOffset,
      _pagination.limit,
      _pagination.nextPage,
      param,
    );
    _pagination = Pagination(
      limit: fetchLimit,
      offset: _pagination.nextOffset,
      total: _pagination.total + response.length,
    );
    _data.addAll(response);
    return response;
  }
}

/// Type definition for cursor-based pagination data fetcher.
///
/// Parameters:
/// - [cursor]: The cursor for pagination, or null for the initial request
/// - [limit]: Number of items to fetch
/// - [param]: Optional parameter for filtering/querying
///
/// Returns: Response containing items and next cursor data
typedef FetchCursorPaginationData<R, P, C> =
    Future<R> Function(C? cursor, int limit, [P? param]);

/// Type definition for extracting items from a cursor pagination response.
typedef FetchItemsFromResponse<R, T> = List<T> Function(R response);

/// Type definition for extracting the next cursor from a response.
typedef FetchCursorValue<C, R> = C? Function(R response);

/// A use case for listing data with cursor-based pagination.
///
/// This class manages cursor state and data fetching for APIs that use cursors
/// instead of offsets.
///
/// Type parameters:
/// - [T]: The type of items in the list
/// - [F]: The type of optional parameters for filtering/querying
/// - [R]: The type of API response
/// - [C]: The type of cursor, such as String or DateTime
class CursorListingUseCase<T, F, R, C> {
  /// Creates a [CursorListingUseCase] with response extraction callbacks.
  ///
  /// Parameters:
  /// - [_fetchPaginationData]: Function to fetch paginated data
  /// - [_fetchItemsFromResponse]: Function to extract items from the response
  /// - [_fetchCursorValue]: Function to extract the next cursor from the
  ///   response
  /// - [_fetchLimit]: Number of items per page
  CursorListingUseCase(
    this._fetchPaginationData,
    this._fetchItemsFromResponse,
    this._fetchCursorValue, [
    this._fetchLimit = PaginationConstant.lowLimit,
  ]);

  /// Callback function to fetch paginated data with a cursor
  final FetchCursorPaginationData<R, F, C> _fetchPaginationData;

  /// Function to extract items from the response
  final FetchItemsFromResponse<R, T> _fetchItemsFromResponse;

  /// Function to extract the next cursor from the response
  final FetchCursorValue<C, R> _fetchCursorValue;

  /// Cached list of fetched items
  final List<T> _data = <T>[];

  /// Number of items to fetch per request
  final int _fetchLimit;

  /// Current cursor for the next page
  C? _cursor;

  /// Gets the current fetch limit
  int get fetchLimit => _fetchLimit;

  /// Gets the cached data
  List<T> get data => _data;

  /// Indicates whether another cursor page is available
  bool get canNext => switch (_cursor.runtimeType) {
    String => (_cursor as String).isNotEmpty,
    _ => _cursor != null,
  };

  /// Fetches the initial data, resetting cursor state.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of fetched items
  Future<List<T>> getData([F? param]) async {
    _cursor = null;
    _data.clear();
    return _fetchData(param);
  }

  /// Loads more data using the current cursor.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of newly fetched items
  Future<List<T>> loadMoreData([F? param]) {
    return _fetchData(param);
  }

  /// Internal method to fetch data and update cursor state.
  ///
  /// Parameters:
  /// - [param]: Optional parameter for filtering/querying
  ///
  /// Returns: List of fetched items
  Future<List<T>> _fetchData([F? param]) async {
    final response = await _fetchPaginationData(_cursor, _fetchLimit, param);
    _cursor = _fetchCursorValue(response);
    final items = _fetchItemsFromResponse(response);
    _data.addAll(items);
    return items;
  }
}
