# Clerk Authentication Setup for Coursiva iOS

## 1. Add Clerk SDK to Xcode Project

### Step 1: Add Package Dependency
1. Open `coursiva.xcodeproj` in Xcode
2. Select your project in the navigator
3. Go to "Package Dependencies" tab
4. Click the "+" button to add a new package
5. Enter the URL: `https://github.com/clerk/clerk-ios`
6. Click "Add Package"
7. Select "Clerk" and add it to your target

### Step 2: Configure Info.plist (if needed)
If you plan to use OAuth providers or need custom URL schemes, add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>clerk</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-scheme</string>
        </array>
    </dict>
</array>
```

## 2. Clerk Configuration Details

Your Clerk configuration is already set up in the code with the following credentials:

- **Publishable Key**: `pk_test_ZmluZXItcm91Z2h5LTUuY2xlcmsuYWNjb3VudHMuZGV2JA`
- **Frontend API URL**: `https://finer-roughy-5.clerk.accounts.dev`
- **Backend API URL**: `https://api.clerk.com`
- **JWKS URL**: `https://finer-roughy-5.clerk.accounts.dev/.well-known/jwks.json`

## 3. Code Structure

The authentication system has been implemented with the following files:

### Core Files
- `coursivaApp.swift` - Main app file with Clerk initialization
- `ContentView.swift` - Conditional rendering based on auth state

### Authentication Views
- `ClerkAuthView.swift` - Main auth container with sign-in/sign-up toggle
- `ClerkSignInView.swift` - Email/password sign-in
- `ClerkSignUpView.swift` - Email/password sign-up with email verification

### UI Components
- `UIComponents.swift` - Updated with `PrimaryButtonStyle` for auth buttons
- `ProfileView.swift` - Updated to show user data and sign-out functionality

## 4. Features Implemented

✅ **Email/Password Authentication**
- Sign up with email verification
- Sign in with email/password
- Input validation and error handling

✅ **User Interface**
- Consistent with your app's design system
- Loading states for all auth actions
- Smooth animations between sign-in/sign-up

✅ **User Session Management**
- Automatic session persistence
- Sign out functionality
- User data display in profile

✅ **Error Handling**
- User-friendly error messages
- Proper error states for network issues

## 5. Testing the Implementation

### Test Sign Up Flow
1. Run the app
2. Tap "Don't have an account? Sign up"
3. Enter email and password
4. Check your email for verification code
5. Enter the verification code
6. You should be signed in automatically

### Test Sign In Flow
1. If you have an existing account, tap "Already have an account? Sign in"
2. Enter your credentials
3. You should be signed in

### Test Sign Out
1. Go to the Profile tab
2. Tap "Sign Out"
3. You should return to the auth screen

## 6. Webhook Testing (Optional)

For testing webhooks with ngrok:
- **Webhook URL**: `https://0217-95-56-238-194.ngrok-free.app`
- Configure this in your Clerk dashboard under Webhooks

## 7. Next Steps / Enhancements

### Potential Additions
1. **OAuth Providers** (Google, Apple, etc.)
2. **Phone Number Authentication**
3. **Multi-factor Authentication**
4. **Password Reset Flow**
5. **Profile Image Upload**
6. **Organization/Team Features**

### OAuth Integration Example
To add Google OAuth, you would:
1. Configure OAuth in Clerk Dashboard
2. Add OAuth button to `ClerkAuthView`
3. Use Clerk's OAuth methods

## 8. Troubleshooting

### Common Issues
1. **Build Errors**: Make sure Clerk SDK is properly added to your target
2. **Network Errors**: Check your publishable key is correct
3. **Email Verification**: Check spam folder for verification emails
4. **Loading Issues**: Ensure `clerk.load()` is called before showing UI

### Debug Tips
- Enable debug logging in Clerk for development
- Check Console.app for detailed error messages
- Verify network connectivity for API calls

## 9. Security Notes

- ✅ Publishable key is safe to use in frontend code
- ✅ Never commit secret keys to version control
- ✅ Use environment variables for production deployments
- ✅ Always validate user sessions on your backend

## 10. Production Checklist

Before deploying to production:
- [ ] Replace test keys with production keys
- [ ] Configure custom email templates in Clerk
- [ ] Set up proper webhook endpoints
- [ ] Test all authentication flows thoroughly
- [ ] Configure proper redirect URLs
- [ ] Set up monitoring and analytics 