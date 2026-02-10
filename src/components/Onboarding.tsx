import { useState } from 'react';
import { useNavigate } from 'react-router';
import { UserProfile, saveUserProfile, getBookRecommendations } from '../lib/storage';
import { User, GraduationCap, BookOpen, Sparkles } from 'lucide-react';

export function Onboarding() {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState<Partial<UserProfile>>({
    age: undefined,
    education: '',
    booksPerYear: undefined,
    favoriteGenres: [],
  });

  const handleComplete = () => {
    const profile: UserProfile = {
      age: formData.age!,
      education: formData.education!,
      booksPerYear: formData.booksPerYear!,
      favoriteGenres: formData.favoriteGenres!,
      onboardingComplete: true,
    };
    saveUserProfile(profile);
    navigate('/upload');
  };

  const recommendations = formData.booksPerYear 
    ? getBookRecommendations(formData as UserProfile)
    : [];

  if (step === 1) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
          <div className="text-center mb-8">
            <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-4 rounded-full w-fit mx-auto mb-4">
              <Sparkles className="size-12 text-white" />
            </div>
            <h1 className="text-3xl font-bold mb-2">Welcome to ReadQuest!</h1>
            <p className="text-gray-600">
              Let's personalize your reading experience
            </p>
          </div>

          <div className="space-y-6">
            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                <User className="size-4" />
                What's your age?
              </label>
              <input
                type="number"
                min="1"
                max="120"
                value={formData.age || ''}
                onChange={(e) => setFormData({ ...formData, age: parseInt(e.target.value) })}
                placeholder="Enter your age"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>

            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                <GraduationCap className="size-4" />
                Education Level
              </label>
              <select
                value={formData.education || ''}
                onChange={(e) => setFormData({ ...formData, education: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              >
                <option value="">Select your education level</option>
                <option value="high-school">High School</option>
                <option value="some-college">Some College</option>
                <option value="bachelors">Bachelor's Degree</option>
                <option value="masters">Master's Degree</option>
                <option value="doctorate">Doctorate</option>
              </select>
            </div>

            <div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                <BookOpen className="size-4" />
                How many books do you read per year?
              </label>
              <input
                type="number"
                min="0"
                max="1000"
                value={formData.booksPerYear || ''}
                onChange={(e) => setFormData({ ...formData, booksPerYear: parseInt(e.target.value) })}
                placeholder="e.g., 12"
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>

            <button
              onClick={() => setStep(2)}
              disabled={!formData.age || !formData.education || !formData.booksPerYear}
              className="w-full bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Continue
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full">
        <div className="text-center mb-8">
          <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-4 rounded-full w-fit mx-auto mb-4">
            <BookOpen className="size-12 text-white" />
          </div>
          <h2 className="text-2xl font-bold mb-2">Favorite Genres</h2>
          <p className="text-gray-600">
            Select your favorite genres to get better recommendations
          </p>
        </div>

        <div className="space-y-6">
          <div className="grid grid-cols-2 gap-3">
            {[
              'Fiction',
              'Non-Fiction',
              'Mystery',
              'Romance',
              'Sci-Fi',
              'Fantasy',
              'Biography',
              'History',
              'Self-Help',
              'Thriller',
              'Classics',
              'Poetry',
            ].map((genre) => {
              const isSelected = formData.favoriteGenres?.includes(genre);
              return (
                <button
                  key={genre}
                  onClick={() => {
                    const genres = formData.favoriteGenres || [];
                    if (isSelected) {
                      setFormData({
                        ...formData,
                        favoriteGenres: genres.filter((g) => g !== genre),
                      });
                    } else {
                      setFormData({
                        ...formData,
                        favoriteGenres: [...genres, genre],
                      });
                    }
                  }}
                  className={`px-4 py-3 rounded-lg border-2 transition-all ${
                    isSelected
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                      : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {genre}
                </button>
              );
            })}
          </div>

          {recommendations.length > 0 && (
            <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
              <p className="text-sm font-medium text-purple-900 mb-2">
                📚 Recommended for you:
              </p>
              <ul className="text-sm text-purple-700 space-y-1">
                {recommendations.map((book) => (
                  <li key={book}>• {book}</li>
                ))}
              </ul>
            </div>
          )}

          <div className="flex gap-3">
            <button
              onClick={() => setStep(1)}
              className="flex-1 bg-gray-200 text-gray-700 px-6 py-3 rounded-lg hover:bg-gray-300 transition-colors"
            >
              Back
            </button>
            <button
              onClick={handleComplete}
              disabled={!formData.favoriteGenres?.length}
              className="flex-1 bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Get Started
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
