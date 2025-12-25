# Supabase Email Confirmation Setup for Mobile

## The Problem
When a user clicks the email confirmation link, Supabase redirects to `localhost:3000` which doesn't work on mobile devices/emulators.

## Solution: Configure Deep Linking

### Step 1: Configure Supabase Dashboard

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Update **Site URL** to: `com.example.groceryapp://login-callback`
3. Add to **Redirect URLs**: `com.example.groceryapp://login-callback`
4. Click **Save**

### Step 2: Android Configuration ✅ (Already Done)
The `AndroidManifest.xml` has been updated with the deep link intent filter.

### Step 3: Handle Auth Callback in App
The app will automatically handle the deep link and process the auth code.

## Alternative: Disable Email Confirmation (For Development)

If you want to skip email confirmation during development:

1. Go to **Supabase Dashboard** → **Authentication** → **Providers**
2. Click on **Email**
3. Toggle OFF **Confirm email**
4. Click **Save**

This allows users to sign up without email verification (not recommended for production).

## Testing
After configuring:
1. Rebuild the app: `flutter run`
2. Sign up with a new email
3. Click the confirmation link in the email
4. The app should open and log you in automatically
