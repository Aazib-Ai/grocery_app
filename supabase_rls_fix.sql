-- ============================================
-- FIX: Infinite Recursion in RLS Policies
-- ============================================
-- The issue: Admin check policies query the profiles table, 
-- which triggers the same policies, causing infinite recursion.
--
-- Solution: Use a SECURITY DEFINER function to check admin status
-- without triggering RLS policies.

-- Step 1: Create a function that bypasses RLS to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Drop the problematic policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Step 3: Recreate policies using the new function
-- The SECURITY DEFINER function bypasses RLS, preventing recursion

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can update all profiles" ON public.profiles
  FOR UPDATE USING (public.is_admin());

-- ============================================
-- Now run this in Supabase SQL Editor
-- ============================================
