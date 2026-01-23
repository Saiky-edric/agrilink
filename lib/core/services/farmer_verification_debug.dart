import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Debug service to isolate the exact cause of the verification failure
class FarmerVerificationDebugService {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Comprehensive debug test for verification submission
  Future<Map<String, dynamic>> debugVerificationIssue({
    required String farmerId,
    required String farmName,
    required String farmAddress,
  }) async {
    final debugResults = <String, dynamic>{};
    
    print('🔍 === STARTING COMPREHENSIVE DEBUG ===');

    try {
      // Test 1: Check authentication
      print('🔍 TEST 1: Authentication Check');
      final currentUser = _supabase.client.auth.currentUser;
      debugResults['auth_test'] = {
        'has_user': currentUser != null,
        'user_id': currentUser?.id,
        'user_email': currentUser?.email,
        'user_metadata': currentUser?.userMetadata,
      };
      print('   ✅ Current User: ${currentUser?.id}');
      print('   ✅ Email: ${currentUser?.email}');

      if (currentUser == null) {
        debugResults['error'] = 'No authenticated user found';
        return debugResults;
      }

      // Test 2: Check user in database
      print('🔍 TEST 2: Database User Check');
      final userCheck = await _supabase.client
          .from('users')
          .select('id, role, is_active, full_name, email')
          .eq('id', farmerId)
          .maybeSingle();
      
      debugResults['user_check'] = userCheck;
      print('   ✅ User found: ${userCheck != null}');
      if (userCheck != null) {
        print('   ✅ Role: ${userCheck['role']}');
        print('   ✅ Active: ${userCheck['is_active']}');
      }

      // Test 3: Test table access
      print('🔍 TEST 3: Table Access Test');
      try {
        final tableTest = await _supabase.client
            .from('farmer_verifications')
            .select('count')
            .limit(1);
        debugResults['table_access'] = 'SUCCESS';
        print('   ✅ Can access farmer_verifications table');
      } catch (e) {
        debugResults['table_access'] = 'FAILED: $e';
        print('   ❌ Cannot access table: $e');
      }

      // Test 4: Test minimal insert (without files)
      print('🔍 TEST 4: Minimal Insert Test');
      final minimalData = {
        'farmer_id': farmerId,
        'farm_name': 'DEBUG_TEST',
        'farm_address': 'DEBUG_ADDRESS',
        'farmer_id_image_url': 'debug-url-1',
        'barangay_cert_image_url': 'debug-url-2',
        'selfie_image_url': 'debug-url-3',
        'status': 'pending',
      };

      try {
        print('   🔍 Attempting minimal insert...');
        final insertResult = await _supabase.client
            .from('farmer_verifications')
            .insert(minimalData)
            .select()
            .single();
        
        debugResults['minimal_insert'] = 'SUCCESS';
        print('   ✅ Minimal insert successful!');
        
        // Clean up the test record
        await _supabase.client
            .from('farmer_verifications')
            .delete()
            .eq('id', insertResult['id']);
        print('   ✅ Test record cleaned up');
        
      } catch (e) {
        debugResults['minimal_insert'] = 'FAILED: $e';
        print('   ❌ Minimal insert failed: $e');
      }

      // Test 5: Test with different data variations
      print('🔍 TEST 5: Data Variation Tests');
      
      // Test with minimal fields only
      final minimalFields = {
        'farmer_id': farmerId,
        'farm_name': farmName,
        'farm_address': farmAddress,
        'status': 'pending',
      };

      try {
        await _supabase.client
            .from('farmer_verifications')
            .insert(minimalFields)
            .select()
            .single();
        debugResults['minimal_fields_test'] = 'SUCCESS - Issue is with extra fields';
        print('   ✅ Minimal fields insert worked');
      } catch (e) {
        debugResults['minimal_fields_test'] = 'FAILED: $e';
        print('   ❌ Even minimal fields failed: $e');
      }

      // Test 6: Check RLS policies via function call
      print('🔍 TEST 6: RLS Policy Function Test');
      try {
        final rpcResult = await _supabase.client
            .rpc('test_farmer_verification_access', params: {
              'test_farmer_id': farmerId,
            });
        debugResults['rpc_test'] = rpcResult;
        print('   ✅ RPC test result: $rpcResult');
      } catch (e) {
        debugResults['rpc_test'] = 'RPC function not available: $e';
        print('   ⚠️  RPC test failed (function may not exist): $e');
      }

      // Test 7: Auth context verification
      print('🔍 TEST 7: Authentication Context Test');
      try {
        final authTest = await _supabase.client
            .rpc('auth_uid')
            .single();
        debugResults['auth_context'] = authTest;
        print('   ✅ Auth context: $authTest');
      } catch (e) {
        debugResults['auth_context'] = 'FAILED: $e';
        print('   ❌ Auth context test failed: $e');
      }

    } catch (e) {
      debugResults['critical_error'] = e.toString();
      print('   ❌ Critical error in debug: $e');
    }

    print('🔍 === DEBUG COMPLETE ===');
    return debugResults;
  }

  /// Test different authentication approaches
  Future<void> testAuthApproaches() async {
    print('🔍 === TESTING AUTH APPROACHES ===');

    // Test 1: Direct client auth
    print('🔍 Method 1: Direct Supabase Client');
    final directClient = Supabase.instance.client;
    print('   User: ${directClient.auth.currentUser?.id}');

    // Test 2: Service wrapper auth
    print('🔍 Method 2: SupabaseService Wrapper');
    print('   User: ${_supabase.client.auth.currentUser?.id}');

    // Test 3: Session check
    print('🔍 Method 3: Session Validation');
    final session = _supabase.client.auth.currentSession;
    print('   Session exists: ${session != null}');
    print('   Session user: ${session?.user.id}');
    print('   Session expires: ${session?.expiresAt}');

    print('🔍 === AUTH TESTING COMPLETE ===');
  }

  /// Create a simple test record to isolate the issue
  Future<bool> testSimpleInsert() async {
    try {
      print('🔍 Testing simplest possible insert...');
      
      final testData = {
        'farmer_id': _supabase.client.auth.currentUser!.id,
        'farm_name': 'TEST',
        'farm_address': 'TEST',
        'status': 'pending',
      };

      await _supabase.client
          .from('farmer_verifications')
          .insert(testData);

      print('✅ Simple insert worked! Issue is with complex data.');
      return true;
    } catch (e) {
      print('❌ Simple insert failed: $e');
      return false;
    }
  }

  /// Generate a comprehensive debug report
  Future<String> generateDebugReport() async {
    final report = StringBuffer();
    report.writeln('=== FARMER VERIFICATION DEBUG REPORT ===');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('');

    try {
      // Get debug results
      final currentUser = _supabase.client.auth.currentUser;
      if (currentUser != null) {
        final results = await debugVerificationIssue(
          farmerId: currentUser.id,
          farmName: 'Debug Test Farm',
          farmAddress: 'Debug Test Address',
        );

        report.writeln('AUTH STATUS:');
        report.writeln('  User ID: ${currentUser.id}');
        report.writeln('  Email: ${currentUser.email}');
        report.writeln('');

        report.writeln('DEBUG RESULTS:');
        results.forEach((key, value) {
          report.writeln('  $key: $value');
        });
      } else {
        report.writeln('❌ NO AUTHENTICATED USER');
      }
    } catch (e) {
      report.writeln('❌ ERROR GENERATING REPORT: $e');
    }

    return report.toString();
  }
}