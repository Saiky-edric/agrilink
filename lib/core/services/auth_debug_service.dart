import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to debug authentication context issues
class AuthDebugService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Comprehensive auth debugging
  Future<Map<String, dynamic>> debugAuthContext() async {
    final results = <String, dynamic>{};
    
    print('🔍 === AUTH CONTEXT DEBUG ===');

    try {
      // 1. Check current session
      final session = _client.auth.currentSession;
      results['session'] = {
        'exists': session != null,
        'user_id': session?.user.id,
        'access_token_length': session?.accessToken.length,
        'expires_at': session?.expiresAt,
        'token_type': session?.tokenType,
      };
      
      print('📱 Session exists: ${session != null}');
      if (session != null) {
        print('📱 User ID: ${session.user.id}');
        print('📱 Token length: ${session.accessToken.length}');
        print('📱 Expires: ${session.expiresAt}');
      }

      // 2. Check current user
      final user = _client.auth.currentUser;
      results['user'] = {
        'exists': user != null,
        'id': user?.id,
        'email': user?.email,
        'metadata': user?.userMetadata,
        'app_metadata': user?.appMetadata,
      };
      
      print('👤 User exists: ${user != null}');
      if (user != null) {
        print('👤 User ID: ${user.id}');
        print('👤 Email: ${user.email}');
      }

      // 3. Check request headers
      final headers = _client.rest.headers;
      results['headers'] = {
        'authorization_present': headers.containsKey('Authorization'),
        'authorization_length': headers['Authorization']?.length,
        'apikey_present': headers.containsKey('apikey'),
      };
      
      print('🔑 Headers:');
      print('   - Authorization: ${headers.containsKey('Authorization')} (length: ${headers['Authorization']?.length})');
      print('   - API Key: ${headers.containsKey('apikey')}');

      // 4. Test database auth context
      try {
        final authTest = await _client.rpc('get_current_user_id');
        results['database_auth'] = {
          'success': true,
          'user_id': authTest,
        };
        print('🗄️  Database auth.uid(): $authTest');
      } catch (e) {
        results['database_auth'] = {
          'success': false,
          'error': e.toString(),
        };
        print('🗄️  Database auth test failed: $e');
      }

      // 5. Test simple authenticated query
      try {
        final userQuery = await _client
            .from('users')
            .select('id, role')
            .eq('id', user?.id ?? '')
            .maybeSingle();
        
        results['user_query'] = {
          'success': true,
          'user_found': userQuery != null,
          'user_data': userQuery,
        };
        print('👥 User query result: ${userQuery != null ? 'Found' : 'Not found'}');
      } catch (e) {
        results['user_query'] = {
          'success': false,
          'error': e.toString(),
        };
        print('👥 User query failed: $e');
      }

    } catch (e) {
      results['critical_error'] = e.toString();
      print('💥 Critical error: $e');
    }

    print('🔍 === AUTH DEBUG COMPLETE ===');
    return results;
  }

  /// Test different authentication approaches
  Future<void> testAuthApproaches() async {
    print('🧪 === TESTING AUTH APPROACHES ===');

    // Approach 1: Get fresh session
    try {
      print('🧪 Test 1: Get fresh session');
      await _client.auth.refreshSession();
      final session = _client.auth.currentSession;
      print('   Result: ${session != null ? 'Success' : 'Failed'}');
    } catch (e) {
      print('   Error: $e');
    }

    // Approach 2: Check token validity
    try {
      print('🧪 Test 2: Token validation');
      final user = _client.auth.currentUser;
      if (user != null) {
        // Try a simple authenticated request
        await _client.from('users').select('count').limit(1);
        print('   Result: Token is valid');
      } else {
        print('   Result: No user found');
      }
    } catch (e) {
      print('   Error: $e');
    }

    // Approach 3: Manual JWT inspection
    try {
      print('🧪 Test 3: JWT inspection');
      final session = _client.auth.currentSession;
      if (session != null) {
        print('   Access token starts with: ${session.accessToken.substring(0, 20)}...');
        print('   Token type: ${session.tokenType}');
        final expiresAt = session.expiresAt;
        if (expiresAt != null && expiresAt is int) {
          final expiresDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          print('   Expires in: ${expiresDate.difference(DateTime.now()).inMinutes} minutes');
        } else if (expiresAt != null) {
          print('   Expires at: $expiresAt');
        }
      }
    } catch (e) {
      print('   Error: $e');
    }

    print('🧪 === TESTING COMPLETE ===');
  }

  /// Force refresh authentication
  Future<bool> forceAuthRefresh() async {
    try {
      print('🔄 Forcing auth refresh...');
      
      final response = await _client.auth.refreshSession();
      if (response.session != null) {
        print('✅ Auth refresh successful');
        print('   New token expires: ${response.session!.expiresAt}');
        return true;
      } else {
        print('❌ Auth refresh failed: No session returned');
        return false;
      }
    } catch (e) {
      print('❌ Auth refresh error: $e');
      return false;
    }
  }

  /// Get comprehensive auth report
  Future<String> generateAuthReport() async {
    final report = StringBuffer();
    report.writeln('=== AUTHENTICATION DEBUG REPORT ===');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('');

    final results = await debugAuthContext();
    
    results.forEach((key, value) {
      report.writeln('$key: $value');
    });

    return report.toString();
  }
}