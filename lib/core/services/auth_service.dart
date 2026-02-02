import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../config/environment.dart';
import '../utils/error_handler.dart';
import 'supabase_service.dart';
import 'profile_service.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService.instance;
  final ProfileService _profileService = ProfileService();

  // Get current user
  User? get currentUser => _supabase.currentUser;
  bool get isLoggedIn => _supabase.isLoggedIn;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role.name,
        },
      );

      if (response.user != null) {
        // Create user profile in the users table (linked to auth.users)
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          role: role,
        );
      }

      return response;
    } catch (e) {
      ErrorHandler.logError('Auth Service - Sign Up', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Clear any cached profile data to ensure fresh role data
        _profileService.clearCache();
        
        // Log successful sign-in for debugging
        final user = await getCurrentUserProfile();
        EnvironmentConfig.log('✅ Sign-in successful: ${user?.fullName} (Role: ${user?.role.name})');
      }
      
      return response;
    } catch (e) {
      EnvironmentConfig.logError('❌ Sign-in failed', e);
      rethrow;
    }
  }

  // Sign in and get user with role information
  Future<UserModel?> signInAndGetUser({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await signIn(email: email, password: password);

      if (authResponse.user != null) {
        final user = await getCurrentUserProfile();

        // getCurrentUserProfile will handle the suspension check
        // If the user is suspended, it will sign them out and return null
        return user;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      EnvironmentConfig.log('🚀 Starting Google Sign-In process...');
      
      final webClientId = EnvironmentConfig.googleWebClientId;
      final androidClientId = EnvironmentConfig.googleAndroidClientId;
      
      EnvironmentConfig.log('🔑 Client IDs - Web: $webClientId, Android: $androidClientId');

      // Add serverClientId for Supabase authentication
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: EnvironmentConfig.googleWebClientId, // ← ADDED THIS!
      );

      EnvironmentConfig.log('📱 Initiating Google sign-in...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        EnvironmentConfig.log('❌ Google sign-in was cancelled by user');
        throw Exception('Google sign-in was cancelled');
      }

      EnvironmentConfig.log('✅ Google user obtained: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      EnvironmentConfig.log('🎫 Tokens - Access: ${accessToken?.substring(0, 20)}..., ID: ${idToken?.substring(0, 20)}...');

      if (accessToken == null) {
        throw Exception('No Access Token found');
      }
      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      EnvironmentConfig.log('🔗 Sending to Supabase for authentication...');
      final response = await _supabase.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Check if user profile already exists with a role
        final existingUser = await _supabase.users
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existingUser == null) {
          // Create new user profile without role (will be set in role selection)
          final userId = response.user?.id;
          final userEmail = response.user?.email ?? googleUser.email;
          
          if (userId == null || userEmail == null) {
            throw Exception('Missing user ID or email from authentication response');
          }
          
          await _supabase.users.insert({
            'id': userId,
            'email': userEmail,
            'full_name': googleUser.displayName ?? 'User',
            'phone_number': '',
            'role':
                'buyer', // Default to buyer, will be updated in role selection
            'created_at': DateTime.now().toIso8601String(),
          });

          // Return null to indicate role selection is needed
          return null;
        } else {
          // User exists with a role, return their profile
          return await getCurrentUserProfile();
        }
      }

      return null;
    } catch (e) {
      EnvironmentConfig.logError('🚨 AGRILINK ERROR: Google sign-in error', e);
      
      // Provide specific error guidance
      if (e.toString().contains('Unacceptable audience')) {
        EnvironmentConfig.logError('OAuth Configuration Error', 
          'The Google Client ID is not properly configured in Supabase. '
          'Please check the GOOGLE_SIGNIN_FIX_GUIDE.md for solutions.'
        );
      } else if (e.toString().contains('Invalid client')) {
        EnvironmentConfig.logError('Invalid Client Error', 
          'The Google Client ID is invalid or not found. '
          'Please verify your Google Cloud Console configuration.'
        );
      }
      
      rethrow;
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      // Clear cached profile data first
      _profileService.clearCache();
      
      // Sign out from Supabase
      await _supabase.client.auth.signOut();
      
      EnvironmentConfig.log('✅ User signed out successfully and cache cleared');
    } catch (e) {
      EnvironmentConfig.logError('❌ Error during sign out', e);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      ErrorHandler.logError('Auth Service - Password Reset', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Send OTP to email for signup verification
  Future<void> sendSignupOTP(String email) async {
    try {
      EnvironmentConfig.log('📧 Sending signup OTP to: $email');
      
      await _supabase.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // Not needed for OTP codes
        shouldCreateUser: true, // Allow user creation during OTP signup
      );
      
      EnvironmentConfig.log('✅ Signup OTP sent successfully to: $email');
    } catch (e) {
      EnvironmentConfig.logError('❌ Failed to send signup OTP', e);
      ErrorHandler.logError('Auth Service - Send Signup OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Verify OTP code and create user account for signup
  Future<AuthResponse> verifySignupOTP({
    required String email,
    required String token,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      EnvironmentConfig.log('🔐 Verifying signup OTP for: $email');
      
      final response = await _supabase.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (response.user != null) {
        EnvironmentConfig.log('✅ OTP verified successfully for: ${response.user!.email}');
        
        // Check if user profile already exists
        final existingUser = await _supabase.users
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existingUser == null) {
          EnvironmentConfig.log('👤 Creating user profile after OTP verification...');
          
          // Create user profile with provided information
          await _createUserProfile(
            userId: response.user!.id,
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
            role: role,
          );
          
          EnvironmentConfig.log('✅ Profile created successfully for new user');
        } else {
          EnvironmentConfig.log('✅ User profile already exists');
          
          // Check if user is suspended
          if (existingUser['is_active'] == false) {
            await _supabase.client.auth.signOut();
            throw Exception('Your account has been suspended. Please contact support.');
          }
        }

        // Clear cache and fetch fresh profile
        _profileService.clearCache();
        await getCurrentUserProfile();
      }

      return response;
    } catch (e) {
      EnvironmentConfig.logError('❌ Signup OTP verification failed', e);
      ErrorHandler.logError('Auth Service - Verify Signup OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Resend OTP for signup
  Future<void> resendSignupOTP(String email) async {
    try {
      EnvironmentConfig.log('🔄 Resending signup OTP to: $email');
      await sendSignupOTP(email);
      EnvironmentConfig.log('✅ Signup OTP resent successfully');
    } catch (e) {
      EnvironmentConfig.logError('❌ Failed to resend signup OTP', e);
      ErrorHandler.logError('Auth Service - Resend Signup OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Send OTP for login on untrusted device
  Future<void> sendLoginOTP(String email) async {
    try {
      EnvironmentConfig.log('📧 Sending login OTP to: $email');
      
      await _supabase.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
      );
      
      EnvironmentConfig.log('✅ Login OTP sent successfully to: $email');
    } catch (e) {
      EnvironmentConfig.logError('❌ Failed to send login OTP', e);
      ErrorHandler.logError('Auth Service - Send Login OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Verify OTP code for login on untrusted device
  Future<AuthResponse> verifyLoginOTP({
    required String email,
    required String token,
  }) async {
    try {
      EnvironmentConfig.log('🔐 Verifying login OTP for: $email');
      
      final response = await _supabase.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (response.user != null) {
        EnvironmentConfig.log('✅ Login OTP verified successfully for: ${response.user!.email}');
        
        // Check if user is suspended
        final existingUser = await _supabase.users
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existingUser != null && existingUser['is_active'] == false) {
          await _supabase.client.auth.signOut();
          throw Exception('Your account has been suspended. Please contact support.');
        }

        // Clear cache and fetch fresh profile
        _profileService.clearCache();
        await getCurrentUserProfile();
      }

      return response;
    } catch (e) {
      EnvironmentConfig.logError('❌ Login OTP verification failed', e);
      ErrorHandler.logError('Auth Service - Verify Login OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Resend OTP for login
  Future<void> resendLoginOTP(String email) async {
    try {
      EnvironmentConfig.log('🔄 Resending login OTP to: $email');
      await sendLoginOTP(email);
      EnvironmentConfig.log('✅ Login OTP resent successfully');
    } catch (e) {
      EnvironmentConfig.logError('❌ Failed to resend login OTP', e);
      ErrorHandler.logError('Auth Service - Resend Login OTP', e);
      throw Exception(ErrorHandler.handleAuthError(e));
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (!isLoggedIn) return null;

      final authId = currentUser?.id;
      if (authId == null) {
        EnvironmentConfig.logError('Current user ID is null', 'Cannot fetch user profile');
        return null;
      }
      
      EnvironmentConfig.log('Fetching user profile for Auth ID: $authId');

      // Query users table (primary source for user data)
      final response = await _supabase.users
          .select()
          .eq('id', authId)
          .maybeSingle(); // Use maybeSingle to avoid exceptions

      if (response == null) {
        EnvironmentConfig.logError('No profile found for user: $authId');
        return null;
      }

      EnvironmentConfig.log('User profile response from users: $response');

      final user = UserModel.fromJson(response);

      // Check if user account is active (not suspended)
      if (response['is_active'] == false) {
        await _supabase.client.auth.signOut();
        throw Exception(
          'Your account has been suspended. Please contact support.',
        );
      }

      EnvironmentConfig.log('User profile loaded successfully: ${user.fullName}');
      return user;
    } catch (e) {
      EnvironmentConfig.logError('Failed to get user profile', e, StackTrace.current);
      return null;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? municipality,
    String? barangay,
    String? street,
  }) async {
    try {
      // First check if user exists in users table
      final existingUser = await _supabase.users
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        throw Exception('User profile not found. Please sign up again.');
      }

      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (municipality != null) updateData['municipality'] = municipality;
      if (barangay != null) updateData['barangay'] = barangay;
      if (street != null) updateData['street'] = street;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase.users
          .update(updateData)
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to update user profile');
      }

      return UserModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error updating user profile: User ID: $userId', e);
      rethrow;
    }
  }

  // Check if user has completed address setup
  Future<bool> hasCompletedAddressSetup() async {
    try {
      final user = await getCurrentUserProfile();
      return user?.isAddressComplete ?? false;
    } catch (e) {
      return false;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      final userData = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      // Add role-specific defaults
      if (role == UserRole.farmer) {
        userData.addAll({
          'store_description': 'Fresh agricultural products from our farm.',
          'business_hours': 'Mon-Sun 6:00 AM - 6:00 PM',
          'is_store_open': true,
        });
      }

      await _supabase.users.insert(userData);
    } catch (e) {
      EnvironmentConfig.logError('Error creating user profile', e);
      rethrow;
    }
  }

  // NOTE: This method was removed as it was unused.
  // Social auth now uses the same createUserProfile flow as regular signup.

  // Complete social user profile with role selection
  Future<UserModel> completeSocialUserProfile({
    required String userId,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'role': role.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        updateData['phone_number'] = phoneNumber;
      }

      final response = await _supabase.users
          .update(updateData)
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to complete social user profile');
      }

      return UserModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error completing social user profile', e);
      rethrow;
    }
  }

  // Check if current user is verified farmer
  Future<bool> isFarmerVerified() async {
    try {
      if (!isLoggedIn) return false;

      final user = await getCurrentUserProfile();
      if (user?.role != UserRole.farmer) return false;

      final userId = currentUser?.id;
      if (userId == null) return false;

      final verification = await _supabase.farmerVerifications
          .select()
          .eq('farmer_id', userId)
          .maybeSingle();

      return verification != null && verification['status'] == 'approved';
    } catch (e) {
      return false;
    }
  }
}
