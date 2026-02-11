import { Outlet, Link, useLocation } from 'react-router';
import { BookOpen, Upload, Calendar, MessageCircle, Trophy, Headphones } from 'lucide-react';

export function Root() {
  const location = useLocation();

  const navItems = [
    { path: '/', icon: BookOpen, label: 'Dashboard', gradient: 'from-blue-500 to-cyan-500' },
    { path: '/upload', icon: Upload, label: 'Upload', gradient: 'from-purple-500 to-pink-500' },
    { path: '/plan', icon: Calendar, label: 'Plan', gradient: 'from-green-500 to-emerald-500' },
    { path: '/audio', icon: Headphones, label: 'Audio', gradient: 'from-violet-500 to-purple-500' },
    { path: '/chat', icon: MessageCircle, label: 'Chat', gradient: 'from-orange-500 to-red-500' },
    { path: '/achievements', icon: Trophy, label: 'Achievements', gradient: 'from-amber-500 to-yellow-500' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100">
      {/* Header with Gradient */}
      <header className="sticky top-0 z-50 backdrop-blur-md bg-white/70 border-b border-white/20 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <Link to="/" className="flex items-center gap-3 group">
              <div className="bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 p-2.5 rounded-xl shadow-lg transform group-hover:scale-110 transition-transform duration-300">
                <BookOpen className="size-7 text-white" />
              </div>
              <div>
                <h1 className="font-bold text-2xl bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
                  Booklify
                </h1>
                <p className="text-xs text-gray-600 font-medium">Gamify Your Reading Journey</p>
              </div>
            </Link>
          </div>
        </div>
      </header>

      {/* Navigation with Gradient Indicators */}
      <nav className="sticky top-[72px] z-40 backdrop-blur-md bg-white/60 border-b border-white/20 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex gap-2 overflow-x-auto scrollbar-hide">
            {navItems.map((item) => {
              const isActive = location.pathname === item.path;
              const Icon = item.icon;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center gap-2 px-4 py-3 relative transition-all whitespace-nowrap group ${
                    isActive
                      ? 'text-indigo-700'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {/* Gradient Indicator */}
                  {isActive && (
                    <div className={`absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r ${item.gradient}`} />
                  )}
                  
                  {/* Icon with gradient background on hover/active */}
                  <div className={`p-1.5 rounded-lg transition-all ${
                    isActive 
                      ? `bg-gradient-to-br ${item.gradient} shadow-md` 
                      : 'group-hover:bg-gray-100'
                  }`}>
                    <Icon className={`size-4 ${isActive ? 'text-white' : 'text-current'}`} />
                  </div>
                  
                  <span className={`text-sm font-medium ${isActive ? 'font-bold' : ''}`}>
                    {item.label}
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content with animated gradient background */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Outlet />
      </main>

      {/* Floating gradient orbs for background effect */}
      <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-br from-purple-300/30 to-pink-300/30 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-to-br from-blue-300/30 to-cyan-300/30 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
      </div>
    </div>
  );
}