-- Enable RLS on profiles table (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy for SELECT: Users can view their own profile
CREATE POLICY "Users can view their own profile" ON profiles
FOR SELECT USING (auth.uid() = user_id);

-- Policy for INSERT: Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for UPDATE: Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
FOR UPDATE USING (auth.uid() = user_id);

-- For storage bucket 'avatars', add policies if needed
-- In Storage > avatars > Policies, add:
-- SELECT: auth.uid()::text = (storage.foldername(name))[1]
-- INSERT: auth.uid()::text = (storage.foldername(name))[1]
-- UPDATE: auth.uid()::text = (storage.foldername(name))[1]
