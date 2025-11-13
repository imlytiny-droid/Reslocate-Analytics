/*
  # Create AddedEmail Table with Proper RLS

  1. New Tables
    - `AddedEmail`
      - `id` (serial, primary key) - Auto-incrementing identifier
      - `email` (varchar, unique, not null) - Email address being tracked
      - `first_name` (varchar, nullable) - Optional first name
      - `last_name` (varchar, nullable) - Optional last name
      - `created_by` (uuid, nullable) - User who added this email
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

  2. Security
    - Enable RLS on `AddedEmail` table
    - Add policy for authenticated users to INSERT emails
    - Add policy for authenticated users to READ all emails
    - Add policy for authenticated users to UPDATE their own entries

  3. Indexes
    - Email column for fast lookups
    - Created_at for time-based queries

  4. Triggers
    - Auto-update updated_at timestamp on modifications
*/

-- Create the AddedEmail table
CREATE TABLE IF NOT EXISTS public.AddedEmail (
    id SERIAL PRIMARY KEY,
    email VARCHAR NOT NULL UNIQUE,
    first_name VARCHAR,
    last_name VARCHAR,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_added_email_email ON public.AddedEmail(email);
CREATE INDEX IF NOT EXISTS idx_added_email_created_at ON public.AddedEmail(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_added_email_created_by ON public.AddedEmail(created_by);

-- Create trigger function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_added_email_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to table
DROP TRIGGER IF EXISTS trigger_added_email_updated_at ON public.AddedEmail;
CREATE TRIGGER trigger_added_email_updated_at
    BEFORE UPDATE ON public.AddedEmail
    FOR EACH ROW
    EXECUTE FUNCTION update_added_email_updated_at();

-- Enable Row Level Security
ALTER TABLE public.AddedEmail ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all emails
CREATE POLICY "Authenticated users can read all emails"
    ON public.AddedEmail
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow authenticated users to insert emails
CREATE POLICY "Authenticated users can insert emails"
    ON public.AddedEmail
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Allow users to update emails they created
CREATE POLICY "Users can update their own entries"
    ON public.AddedEmail
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

-- Policy: Allow users to delete emails they created
CREATE POLICY "Users can delete their own entries"
    ON public.AddedEmail
    FOR DELETE
    TO authenticated
    USING (auth.uid() = created_by);

-- Add helpful comments
COMMENT ON TABLE public.AddedEmail IS 'Tracks email addresses added to the system for user management and analytics';
COMMENT ON COLUMN public.AddedEmail.email IS 'Unique email address';
COMMENT ON COLUMN public.AddedEmail.first_name IS 'Optional first name of contact';
COMMENT ON COLUMN public.AddedEmail.last_name IS 'Optional last name of contact';
COMMENT ON COLUMN public.AddedEmail.created_by IS 'UUID of user who added this email';
COMMENT ON COLUMN public.AddedEmail.created_at IS 'Timestamp when email was added';
COMMENT ON COLUMN public.AddedEmail.updated_at IS 'Timestamp of last modification';
