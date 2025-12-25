-- ============================================
-- FIX: Auto-create user profile on signup using a trigger
-- ============================================
-- This approach bypasses RLS issues by creating the profile
-- automatically in the database when a new auth user is created.

-- Step 1: Create a function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, role, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    'customer',
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create a trigger that runs after a new user is created in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 3 (Optional): If you want to also handle profile creation from client side,
-- you need to fix the RLS policy by using a service role or bypassing RLS for inserts.
-- The trigger above is the recommended approach.

-- ============================================
-- ALTERNATIVE FIX: If you want to keep client-side profile creation
-- ============================================
-- Drop the old insert policy and create a new one that always allows insert
-- when auth.uid matches the id being inserted (no subquery dependencies)

-- DROP POLICY IF EXISTS "Users can insert own profile on signup" ON public.profiles;
-- CREATE POLICY "Users can insert own profile on signup" ON public.profiles
--   FOR INSERT WITH CHECK (auth.uid() = id);

-- Note: The trigger approach (above) is cleaner and more reliable.
