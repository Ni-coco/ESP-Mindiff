import 'package:flutter_test/flutter_test.dart';
import 'package:mindiff_app/features/user_profile/data/datasources/user_datasource_impl.dart';
import 'package:postgres/postgres.dart';

class FakeConnection extends Fake implements Connection {
  Result nextResult = Result(
    rows: const [],
    affectedRows: 0,
    schema: ResultSchema(const []),
  );
  Object? lastQuery;
  Object? lastParameters;

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    lastQuery = query;
    lastParameters = parameters;
    return nextResult;
  }
}

void main() {
  late FakeConnection connection;
  late UserDataSourceImpl dataSource;

  setUp(() {
    connection = FakeConnection();
    dataSource = UserDataSourceImpl(connection);
  });

  test('getUserById retourne null si la requête est vide', () async {
    final result = await dataSource.getUserById(123);

    expect(result, isNull);
    expect(connection.lastParameters, {'id': 123});
  });

  test('deleteUser exécute une suppression avec le bon id', () async {
    await dataSource.deleteUser(42);

    expect(connection.lastParameters, {'id': 42});
  });
}
