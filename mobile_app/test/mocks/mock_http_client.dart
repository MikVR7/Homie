import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return super.noSuchMethod(
      Invocation.method(#get, [url], {#headers: headers}),
      returnValue: Future.value(http.Response('{}', 200)),
      returnValueForMissingStub: Future.value(http.Response('{}', 200)),
    );
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #post,
        [url],
        {
          #headers: headers,
          #body: body,
          #encoding: encoding,
        },
      ),
      returnValue: Future.value(http.Response('{}', 200)),
      returnValueForMissingStub: Future.value(http.Response('{}', 200)),
    );
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #put,
        [url],
        {
          #headers: headers,
          #body: body,
          #encoding: encoding,
        },
      ),
      returnValue: Future.value(http.Response('{}', 200)),
      returnValueForMissingStub: Future.value(http.Response('{}', 200)),
    );
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #delete,
        [url],
        {
          #headers: headers,
          #body: body,
          #encoding: encoding,
        },
      ),
      returnValue: Future.value(http.Response('{}', 200)),
      returnValueForMissingStub: Future.value(http.Response('{}', 200)),
    );
  }

  @override
  void close() => super.noSuchMethod(Invocation.method(#close, []));
}