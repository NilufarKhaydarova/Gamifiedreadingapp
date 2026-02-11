import { useNavigate } from 'react-router';
import { useEffect, useState } from 'react';
import { BookOpen, Calendar, Flame, Target, CheckCircle2, Upload, MessageCircle, Zap } from 'lucide-react';
import { getStoredBook, getProgress, updateProgress, addXP, getXPForNextLevel } from '../lib/storage';

export function Dashboard() {
  const navigate = useNavigate();
  const [book, setBook] = useState<any>(null);
  const [progress, setProgress] = useState<any>(null);

  useEffect(() => {
    const storedBook = getStoredBook();
    const storedProgress = getProgress();
    setBook(storedBook);
    setProgress(storedProgress);
  }, []);

  const handleMarkComplete = () => {
    if (progress && book) {
      const today = new Date().toISOString().split('T')[0];
      const newProgress = {
        ...progress,
        completedDays: [...progress.completedDays, today],
        currentDay: Math.min(progress.currentDay + 1, progress.totalDays),
      };
      updateProgress(newProgress);
      
      // Award XP for completing a day
      addXP(50);
      
      setProgress(newProgress);
    }
  };

  if (!book) {
    return (
      <div className="flex flex-col items-center justify-center py-16">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md text-center">
          <div className="bg-indigo-100 rounded-full p-6 w-fit mx-auto mb-4">
            <BookOpen className="size-12 text-indigo-600" />
          </div>
          <h2 className="text-2xl font-bold mb-2">Start Your Reading Journey</h2>
          <p className="text-gray-600 mb-6">
            Upload a book to begin your gamified reading experience with daily goals, quizzes, and AI-powered discussions.
          </p>
          <button
            onClick={() => navigate('/upload')}
            className="bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors flex items-center gap-2 mx-auto"
          >
            <Upload className="size-5" />
            Upload Your First Book
          </button>
        </div>
      </div>
    );
  }

  const today = new Date().toISOString().split('T')[0];
  const todayCompleted = progress?.completedDays.includes(today);
  const progressPercentage = progress ? (progress.currentDay / progress.totalDays) * 100 : 0;
  const streak = progress ? calculateStreak(progress.completedDays) : 0;
  const xpForNextLevel = progress ? getXPForNextLevel(progress.level) : 100;
  const xpProgress = progress ? (progress.xp / xpForNextLevel) * 100 : 0;

  return (
    <div className="space-y-6">
      {/* Level Card with Enhanced Gradient */}
      <div className="relative overflow-hidden bg-gradient-to-br from-amber-400 via-orange-500 to-rose-600 rounded-2xl shadow-2xl p-6 text-white transform hover:scale-[1.02] transition-all duration-300">
        {/* Animated gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/10 to-transparent animate-pulse" />
        
        <div className="relative z-10">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="bg-white/20 backdrop-blur-sm rounded-full p-3 shadow-lg">
                <Zap className="size-8 text-white drop-shadow-lg" />
              </div>
              <div>
                <p className="text-amber-100 text-sm font-medium">Reader Level</p>
                <p className="text-4xl font-bold drop-shadow-lg">{progress?.level || 1}</p>
              </div>
            </div>
            <div className="text-right bg-white/10 backdrop-blur-sm rounded-xl px-4 py-2 shadow-lg">
              <p className="text-amber-100 text-sm">XP Points</p>
              <p className="text-2xl font-bold">{progress?.xp || 0} / {xpForNextLevel}</p>
            </div>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-full h-4 overflow-hidden shadow-inner">
            <div
              className="bg-gradient-to-r from-white to-amber-100 h-full rounded-full transition-all duration-500 shadow-lg"
              style={{ width: `${xpProgress}%` }}
            />
          </div>
          <p className="text-amber-100 text-sm mt-2 font-medium">
            ⚡ {Math.round(xpForNextLevel - (progress?.xp || 0))} XP until Level {(progress?.level || 1) + 1}
          </p>
        </div>
      </div>

      {/* Current Book Card with Enhanced Gradient */}
      <div className="relative overflow-hidden bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-600 rounded-2xl shadow-2xl p-6 text-white transform hover:scale-[1.01] transition-all duration-300">
        {/* Animated shimmer effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -skew-x-12 animate-shimmer" />
        
        <div className="relative z-10">
          <div className="flex items-start justify-between mb-4">
            <div className="flex-1">
              <p className="text-indigo-200 text-sm mb-1 font-medium">Currently Reading</p>
              <h2 className="text-3xl font-bold mb-1 drop-shadow-lg">{book.title}</h2>
              <p className="text-indigo-200">by {book.author}</p>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-xl px-4 py-3 shadow-lg">
              <p className="text-sm text-indigo-200">Day</p>
              <p className="text-3xl font-bold">{progress?.currentDay || 1}/{progress?.totalDays || 1}</p>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="bg-white/20 backdrop-blur-sm rounded-full h-4 mb-2 overflow-hidden shadow-inner">
            <div
              className="bg-gradient-to-r from-white via-indigo-100 to-white h-full rounded-full transition-all duration-500 shadow-lg"
              style={{ width: `${progressPercentage}%` }}
            />
          </div>
          <p className="text-sm text-indigo-200 font-medium">
            📖 {Math.round(progressPercentage)}% Complete
          </p>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl shadow p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="bg-orange-100 p-2 rounded-lg">
              <Flame className="size-6 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{streak}</p>
              <p className="text-sm text-gray-600">Day Streak</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="bg-green-100 p-2 rounded-lg">
              <CheckCircle2 className="size-6 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{progress?.completedDays.length || 0}</p>
              <p className="text-sm text-gray-600">Days Completed</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="bg-blue-100 p-2 rounded-lg">
              <Target className="size-6 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{book.totalPages}</p>
              <p className="text-sm text-gray-600">Total Pages</p>
            </div>
          </div>
        </div>
      </div>

      {/* Today's Reading */}
      <div className="bg-white rounded-xl shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Calendar className="size-5 text-indigo-600" />
            <h3 className="font-bold">Today's Reading</h3>
          </div>
          {todayCompleted && (
            <span className="bg-green-100 text-green-700 text-sm px-3 py-1 rounded-full flex items-center gap-1">
              <CheckCircle2 className="size-4" />
              Completed
            </span>
          )}
        </div>

        {progress && (
          <div className="space-y-3">
            {/* Theme Badge */}
            <div className="bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-200 rounded-lg p-4">
              <p className="text-xs text-purple-600 font-medium mb-1">TODAY'S THEME</p>
              <p className="font-bold text-purple-900 mb-2">
                {progress.dailyPages[progress.currentDay - 1]?.theme || 'Reading Session'}
              </p>
              <p className="text-sm text-gray-700">
                {progress.dailyPages[progress.currentDay - 1]?.summary || 'Continue your reading journey today.'}
              </p>
            </div>

            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-600 mb-1">Today's Pages</p>
              <p className="text-lg font-bold">
                Pages {progress.dailyPages[progress.currentDay - 1]?.start || 1} - {progress.dailyPages[progress.currentDay - 1]?.end || 1}
              </p>
              <p className="text-sm text-gray-600 mt-1">
                ({progress.dailyPages[progress.currentDay - 1]?.pages || 0} pages)
              </p>
            </div>

            {!todayCompleted && (
              <button
                onClick={handleMarkComplete}
                className="w-full bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors flex items-center justify-center gap-2"
              >
                <CheckCircle2 className="size-5" />
                Mark Today's Reading Complete
              </button>
            )}
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <button
          onClick={() => navigate('/chat')}
          className="bg-white rounded-xl shadow p-6 hover:shadow-lg transition-shadow text-left group"
        >
          <div className="bg-purple-100 p-3 rounded-lg w-fit mb-3 group-hover:scale-110 transition-transform">
            <MessageCircle className="size-6 text-purple-600" />
          </div>
          <h3 className="font-bold mb-1">AI Reading Companion</h3>
          <p className="text-sm text-gray-600">
            Discuss, quiz, and deepen your understanding with Socratic learning
          </p>
        </button>

        <button
          onClick={() => navigate('/plan')}
          className="bg-white rounded-xl shadow p-6 hover:shadow-lg transition-shadow text-left group"
        >
          <div className="bg-blue-100 p-3 rounded-lg w-fit mb-3 group-hover:scale-110 transition-transform">
            <Calendar className="size-6 text-blue-600" />
          </div>
          <h3 className="font-bold mb-1">View Reading Plan</h3>
          <p className="text-sm text-gray-600">
            See your complete daily reading schedule and adjust as needed
          </p>
        </button>
      </div>
    </div>
  );
}

function calculateStreak(completedDays: string[]): number {
  if (completedDays.length === 0) return 0;

  const sortedDays = completedDays.sort().reverse();
  let streak = 0;
  let currentDate = new Date();

  for (let i = 0; i < sortedDays.length; i++) {
    const checkDate = new Date(currentDate);
    checkDate.setDate(checkDate.getDate() - i);
    const checkDateStr = checkDate.toISOString().split('T')[0];

    if (sortedDays.includes(checkDateStr)) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}