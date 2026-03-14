-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Books table
CREATE TABLE IF NOT EXISTS public.books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  total_pages INTEGER,
  content TEXT,
  file_path TEXT,
  cover_url TEXT,
  isbn TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Book chunks (for smart chunking)
CREATE TABLE IF NOT EXISTS public.book_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  chunk_number INTEGER NOT NULL,
  episode_title TEXT,
  key_idea TEXT,
  preview TEXT,
  difficulty TEXT CHECK (difficulty IN ('light', 'moderate', 'dense')),
  estimated_minutes INTEGER,
  start_offset INTEGER,
  end_offset INTEGER,
  content TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(book_id, chunk_number)
);

-- Reading progress table
CREATE TABLE IF NOT EXISTS public.reading_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  current_day INTEGER DEFAULT 0,
  total_days INTEGER DEFAULT 30,
  completed_days TEXT[] DEFAULT '{}',
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  last_session_date TIMESTAMPTZ,
  streak_days INTEGER DEFAULT 0,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  completed_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- Reading sessions log
CREATE TABLE IF NOT EXISTS public.reading_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  chunk_id UUID REFERENCES public.book_chunks(id) ON DELETE SET NULL,
  day_number INTEGER NOT NULL,
  minutes_read INTEGER NOT NULL,
  pages_read INTEGER DEFAULT 0,
  comprehension_score DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Achievements table
CREATE TABLE IF NOT EXISTS public.achievements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_url TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('streak', 'reading_speed', 'comprehension', 'social', 'level')),
  target_value INTEGER,
  xp_reward INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User achievements
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Daily challenges
CREATE TABLE IF NOT EXISTS public.daily_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  target_minutes INTEGER DEFAULT 15,
  completed_minutes INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  xp_reward INTEGER DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- AI chat history (for RAG context)
CREATE TABLE IF NOT EXISTS public.ai_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES public.books(id) ON DELETE SET NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  context_page INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User preferences
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  daily_reading_goal INTEGER DEFAULT 15,
  preferred_difficulty TEXT CHECK (preferred_difficulty IN ('light', 'moderate', 'dense')),
  notification_enabled BOOLEAN DEFAULT TRUE,
  notification_time TIME DEFAULT '09:00:00',
  theme TEXT DEFAULT 'system',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_books_user_id ON public.books(user_id);
CREATE INDEX IF NOT EXISTS idx_book_chunks_book_id ON public.book_chunks(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_progress_user_id ON public.reading_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_progress_book_id ON public.reading_progress(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_user_id ON public.reading_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_created_at ON public.reading_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_challenges_user_date ON public.daily_challenges(user_id, date);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_user_book ON public.ai_chat_messages(user_id, book_id);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.book_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own books" ON public.books
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own books" ON public.books
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own books" ON public.books
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own books" ON public.books
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view chunks of own books" ON public.book_chunks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.books
      WHERE books.id = book_chunks.book_id
      AND books.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view own progress" ON public.reading_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON public.reading_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON public.reading_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own sessions" ON public.reading_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.reading_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements" ON public.user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON public.user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own challenges" ON public.daily_challenges
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenges" ON public.daily_challenges
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenges" ON public.daily_challenges
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own chat messages" ON public.ai_chat_messages
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chat messages" ON public.ai_chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- Public access for achievements (everyone can see achievement definitions)
CREATE POLICY "Anyone can view achievements" ON public.achievements
  FOR SELECT USING (true);

-- Insert predefined achievements
INSERT INTO public.achievements (id, title, description, icon_url, category, target_value, xp_reward) VALUES
  ('first_leaf', 'First Leaf', 'Complete your first reading day', 'assets/icons/achievements/first_leaf.png', 'streak', 1, 25),
  ('week_warrior', 'Week Warrior', 'Maintain a 7-day reading streak', 'assets/icons/achievements/week_warrior.png', 'streak', 7, 100),
  ('kindled', 'Kindled', 'Maintain a 14-day reading streak', 'assets/icons/achievements/kindled.png', 'streak', 14, 200),
  ('electrified', 'Electrified', 'Maintain a 30-day reading streak', 'assets/icons/achievements/electrified.png', 'streak', 30, 500),
  ('in_flow', 'In Flow', 'Maintain a 60-day reading streak', 'assets/icons/achievements/in_flow.png', 'streak', 60, 1000),
  ('speed_reader', 'Speed Reader', 'Read 80+ pages per hour', 'assets/icons/achievements/speed_reader.png', 'reading_speed', 80, 150),
  ('quick_study', 'Quick Study', 'Read 50+ pages per hour', 'assets/icons/achievements/quick_study.png', 'reading_speed', 50, 75),
  ('bookworm', 'Bookworm', 'Complete 5 books', 'assets/icons/achievements/bookworm.png', 'level', 5, 500),
  ('scholar', 'Scholar', 'Complete 10 books', 'assets/icons/achievements/scholar.png', 'level', 10, 1000),
  ('master', 'Master', 'Complete 25 books', 'assets/icons/achievements/master.png', 'level', 25, 2500)
ON CONFLICT (id) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_progress_updated_at BEFORE UPDATE ON public.reading_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_challenges_updated_at BEFORE UPDATE ON public.daily_challenges
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to calculate user XP from reading progress
CREATE OR REPLACE FUNCTION calculate_user_xp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET xp = (
    SELECT COALESCE(SUM(xp), 0)
    FROM public.reading_progress
    WHERE user_id = NEW.user_id
  ),
  level = 1 + (
    SELECT COALESCE(SUM(xp), 0) / 100
    FROM public.reading_progress
    WHERE user_id = NEW.user_id
  )
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update user XP when progress changes
CREATE TRIGGER update_user_xp_on_progress
  AFTER INSERT OR UPDATE ON public.reading_progress
  FOR EACH ROW EXECUTE FUNCTION calculate_user_xp();

-- Create function to update streak
CREATE OR REPLACE FUNCTION update_streak()
RETURNS TRIGGER AS $$
DECLARE
  last_session_date TIMESTAMPTZ;
  days_since_last_session INTEGER;
BEGIN
  -- Get the last session date for this user
  SELECT MAX(created_at) INTO last_session_date
  FROM public.reading_sessions
  WHERE user_id = NEW.user_id;

  -- If there was a previous session
  IF last_session_date IS NOT NULL THEN
    -- Calculate days since last session
    days_since_last_session := EXTRACT(DAY FROM (NEW.created_at - last_session_date));

    -- If the last session was yesterday or today, increment streak
    IF days_since_last_session <= 1 THEN
      UPDATE public.users
      SET current_streak = current_streak + 1,
          longest_streak = GREATEST(longest_streak, current_streak + 1)
      WHERE id = NEW.user_id;
    ELSE
      -- Reset streak if gap is more than 1 day
      UPDATE public.users
      SET current_streak = 1
      WHERE id = NEW.user_id;
    END IF;
  ELSE
    -- First session, set streak to 1
    UPDATE public.users
    SET current_streak = 1
    WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update streak when session is logged
CREATE TRIGGER update_streak_on_session
  AFTER INSERT ON public.reading_sessions
  FOR EACH ROW EXECUTE FUNCTION update_streak();
