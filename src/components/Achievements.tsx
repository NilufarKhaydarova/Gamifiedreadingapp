import { useEffect, useState } from 'react';
import { getProgress } from '../lib/storage';
import { Trophy, Flame, BookOpen, Target, Zap, Star, Award, Medal } from 'lucide-react';

interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: any;
  unlocked: boolean;
  progress?: number;
  target?: number;
}

export function Achievements() {
  const [progress, setProgress] = useState<any>(null);
  const [achievements, setAchievements] = useState<Achievement[]>([]);

  useEffect(() => {
    const storedProgress = getProgress();
    setProgress(storedProgress);

    if (storedProgress) {
      const completedDays = storedProgress.completedDays.length;
      const streak = calculateStreak(storedProgress.completedDays);
      const progressPercent = (storedProgress.currentDay / storedProgress.totalDays) * 100;

      const achievementsList: Achievement[] = [
        {
          id: 'first-day',
          title: 'First Steps',
          description: 'Complete your first day of reading',
          icon: BookOpen,
          unlocked: completedDays >= 1,
        },
        {
          id: 'week-warrior',
          title: 'Week Warrior',
          description: 'Maintain a 7-day reading streak',
          icon: Flame,
          unlocked: streak >= 7,
          progress: Math.min(streak, 7),
          target: 7,
        },
        {
          id: 'dedicated-reader',
          title: 'Dedicated Reader',
          description: 'Read for 14 consecutive days',
          icon: Target,
          unlocked: streak >= 14,
          progress: Math.min(streak, 14),
          target: 14,
        },
        {
          id: 'unstoppable',
          title: 'Unstoppable',
          description: 'Achieve a 30-day reading streak',
          icon: Zap,
          unlocked: streak >= 30,
          progress: Math.min(streak, 30),
          target: 30,
        },
        {
          id: 'quarter-way',
          title: 'Quarter Master',
          description: 'Complete 25% of your book',
          icon: Star,
          unlocked: progressPercent >= 25,
          progress: Math.min(progressPercent, 25),
          target: 25,
        },
        {
          id: 'halfway',
          title: 'Halfway Hero',
          description: 'Reach the halfway point',
          icon: Award,
          unlocked: progressPercent >= 50,
          progress: Math.min(progressPercent, 50),
          target: 50,
        },
        {
          id: 'three-quarters',
          title: 'Almost There',
          description: 'Complete 75% of your book',
          icon: Medal,
          unlocked: progressPercent >= 75,
          progress: Math.min(progressPercent, 75),
          target: 75,
        },
        {
          id: 'book-complete',
          title: 'Book Conqueror',
          description: 'Finish reading your entire book',
          icon: Trophy,
          unlocked: progressPercent >= 100,
          progress: Math.min(progressPercent, 100),
          target: 100,
        },
      ];

      setAchievements(achievementsList);
    }
  }, []);

  if (!progress) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600">Start reading to unlock achievements!</p>
      </div>
    );
  }

  const unlockedCount = achievements.filter((a) => a.unlocked).length;

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-br from-amber-500 to-orange-600 rounded-2xl shadow-lg p-6 text-white">
        <div className="flex items-center gap-3 mb-2">
          <Trophy className="size-10" />
          <div>
            <h2 className="text-2xl font-bold">Your Achievements</h2>
            <p className="text-amber-100">
              {unlockedCount} of {achievements.length} unlocked
            </p>
          </div>
        </div>
        <div className="mt-4 bg-white/20 rounded-full h-3 overflow-hidden">
          <div
            className="bg-white h-full rounded-full transition-all duration-500"
            style={{ width: `${(unlockedCount / achievements.length) * 100}%` }}
          />
        </div>
      </div>

      {/* Achievements Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {achievements.map((achievement) => {
          const Icon = achievement.icon;
          return (
            <div
              key={achievement.id}
              className={`bg-white rounded-xl shadow p-6 transition-all ${
                achievement.unlocked
                  ? 'border-2 border-amber-400'
                  : 'opacity-60 grayscale'
              }`}
            >
              <div className="flex items-start gap-4">
                <div
                  className={`p-3 rounded-lg ${
                    achievement.unlocked
                      ? 'bg-gradient-to-br from-amber-400 to-orange-500'
                      : 'bg-gray-200'
                  }`}
                >
                  <Icon
                    className={`size-8 ${
                      achievement.unlocked ? 'text-white' : 'text-gray-400'
                    }`}
                  />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold mb-1 flex items-center gap-2">
                    {achievement.title}
                    {achievement.unlocked && (
                      <span className="bg-amber-100 text-amber-700 text-xs px-2 py-0.5 rounded-full">
                        Unlocked
                      </span>
                    )}
                  </h3>
                  <p className="text-sm text-gray-600 mb-3">
                    {achievement.description}
                  </p>
                  
                  {achievement.target && !achievement.unlocked && (
                    <div>
                      <div className="bg-gray-200 rounded-full h-2 overflow-hidden">
                        <div
                          className="bg-amber-500 h-full rounded-full transition-all duration-500"
                          style={{
                            width: `${((achievement.progress || 0) / achievement.target) * 100}%`,
                          }}
                        />
                      </div>
                      <p className="text-xs text-gray-500 mt-1">
                        {Math.round(achievement.progress || 0)} / {achievement.target}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
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
