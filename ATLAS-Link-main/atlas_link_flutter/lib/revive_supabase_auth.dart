import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReviveAuthUser {
  const ReviveAuthUser({
    required this.id,
    required this.email,
    required this.pseudo,
    required this.avatarUrl,
  });

  final String id;
  final String email;
  final String pseudo;
  final String avatarUrl;

  factory ReviveAuthUser.fromJson(Map<String, dynamic> json) {
    final metadata = json['user_metadata'] is Map
        ? Map<String, dynamic>.from(json['user_metadata'] as Map)
        : <String, dynamic>{};
    final claims = json['custom_claims'] is Map
        ? Map<String, dynamic>.from(json['custom_claims'] as Map)
        : <String, dynamic>{};
    final pseudo = [
      metadata['pseudo'],
      claims['global_name'],
      metadata['full_name'],
      metadata['name'],
      metadata['preferred_username'],
      (json['email'] is String && (json['email'] as String).contains('@'))
          ? (json['email'] as String).split('@').first
          : null,
    ].whereType<String>().map((value) => value.trim()).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => 'Player',
        );
    return ReviveAuthUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      pseudo: pseudo,
      avatarUrl: (metadata['avatar_url'] ?? '').toString(),
    );
  }
}

/// Discord OAuth account service for Revive. The local loopback callback uses
/// Supabase PKCE; the Discord Gate remains separate and is not touched here.
class ReviveSupabaseAuth {
  ReviveSupabaseAuth({HttpClient? httpClient})
      : _http = httpClient ?? HttpClient();

  static const String _supabaseUrl =
      'https://sjhsfiijtjzaxtttueon.supabase.co';
  static const String _publishableKey =
      'sb_publishable_nCj7qRHvOtcws6Vc3uDJFA_72l5efpJ';
  static const String _accessTokenKey = 'revive.supabase.access_token';
  static const String _refreshTokenKey = 'revive.supabase.refresh_token';

  final HttpClient _http;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  ReviveAuthUser? currentUser;
  String? _accessToken;
  String? _refreshToken;

  Uri get _baseUri => Uri.parse(_supabaseUrl);

  Future<ReviveAuthUser?> restoreSession() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if ((_accessToken ?? '').isEmpty) return null;
    try {
      currentUser = await _getCurrentUser();
    } catch (_) {
      if ((_refreshToken ?? '').isEmpty) {
        await _clearTokens();
        return null;
      }
      try {
        await _refreshSession();
        currentUser = await _getCurrentUser();
      } catch (_) {
        await _clearTokens();
      }
    }
    return currentUser;
  }

  Future<ReviveAuthUser> signInWithDiscord({
    required Future<void> Function(String url) openUrl,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final verifier = _randomVerifier();
    final challenge = base64Url
        .encode(crypto.sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
    final redirectUri = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/auth/callback',
    );
    final authorizeUri = _baseUri.replace(
      path: '/auth/v1/authorize',
      queryParameters: <String, String>{
        'provider': 'discord',
        'redirect_to': redirectUri.toString(),
        'code_challenge': challenge,
        'code_challenge_method': 's256',
      },
    );

    try {
      await openUrl(authorizeUri.toString());
      final request = await server
          .first
          .timeout(const Duration(minutes: 4));
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error_description'] ??
          request.uri.queryParameters['error'];
      request.response
        ..statusCode = code == null ? HttpStatus.badRequest : HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(code == null
            ? '<html><body>Revive sign-in failed. You can close this window.</body></html>'
            : '<html><body>Discord connected to Revive. You can close this window.</body></html>');
      await request.response.close();
      if (code == null || code.isEmpty) {
        throw StateError(error?.isNotEmpty == true
            ? 'Discord sign-in failed: $error'
            : 'Discord sign-in was cancelled or did not return an authorization code.');
      }
      final tokenData = await _postJson(
        '/auth/v1/token?grant_type=pkce',
        <String, dynamic>{
          'auth_code': code,
          'code_verifier': verifier,
        },
      );
      _accessToken = tokenData['access_token']?.toString();
      _refreshToken = tokenData['refresh_token']?.toString();
      if ((_accessToken ?? '').isEmpty) {
        throw StateError('Supabase did not return an access token.');
      }
      await _saveTokens();
      final userJson = tokenData['user'] is Map
          ? Map<String, dynamic>.from(tokenData['user'] as Map)
          : await _getCurrentUserJson();
      currentUser = ReviveAuthUser.fromJson(userJson);
      return currentUser!;
    } finally {
      await server.close(force: true);
    }
  }

  Future<ReviveAuthUser> updatePseudo(String pseudo) async {
    final cleanPseudo = pseudo.trim();
    if (cleanPseudo.isEmpty) throw StateError('Pseudo cannot be empty.');
    final result = await _requestJson(
      'PATCH',
      '/auth/v1/user',
      body: <String, dynamic>{'data': <String, dynamic>{'pseudo': cleanPseudo}},
      authenticated: true,
    );
    currentUser = ReviveAuthUser.fromJson(result);
    return currentUser!;
  }

  Future<void> signOut() async {
    try {
      if ((_accessToken ?? '').isNotEmpty) {
        await _requestJson(
          'POST',
          '/auth/v1/logout',
          authenticated: true,
        );
      }
    } finally {
      await _clearTokens();
      currentUser = null;
    }
  }

  String _randomVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<void> _saveTokens() async {
    if ((_accessToken ?? '').isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
    }
    if ((_refreshToken ?? '').isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
    }
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<void> _refreshSession() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) throw StateError('Session expired.');
    final result = await _postJson(
      '/auth/v1/token?grant_type=refresh_token',
      <String, dynamic>{'refresh_token': refresh},
    );
    _accessToken = result['access_token']?.toString();
    _refreshToken = result['refresh_token']?.toString() ?? refresh;
    await _saveTokens();
  }

  Future<ReviveAuthUser> _getCurrentUser() async =>
      ReviveAuthUser.fromJson(await _getCurrentUserJson());

  Future<Map<String, dynamic>> _getCurrentUserJson() =>
      _requestJson('GET', '/auth/v1/user', authenticated: true);

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) => _requestJson('POST', path, body: body);

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$_supabaseUrl$path');
    final request = await _http.openUrl(method, uri);
    request.headers.set('apikey', _publishableKey);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (authenticated) {
      final token = _accessToken;
      if (token == null || token.isEmpty) throw StateError('Not signed in.');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final responseText = await response.transform(utf8.decoder).join();
    dynamic decoded;
    try {
      decoded = responseText.isEmpty ? <String, dynamic>{} : jsonDecode(responseText);
    } catch (_) {
      decoded = <String, dynamic>{'message': responseText};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['msg'] ?? decoded['message'] ?? decoded['error_description'] ?? decoded['error'] ?? responseText).toString()
          : responseText;
      throw HttpException('Supabase HTTP ${response.statusCode}: $message');
    }
    if (decoded is! Map) throw const FormatException('Invalid Supabase response.');
    return Map<String, dynamic>.from(decoded);
  }

  void dispose() => _http.close(force: true);
}
