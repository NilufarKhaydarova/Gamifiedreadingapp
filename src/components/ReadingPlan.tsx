import { useEffect, useState } from 'react';
import { getStoredBook, getProgress } from '../lib/storage';
import { Calendar, CheckCircle2, Circle, Book } from 'lucide-react';

export function ReadingPlan() {
  const [book, setBook] = useState<any>(null);
  const [progress, setProgress] = useState<any>(null);

  useEffect(() => {
    const storedBook = getStoredBook();
    const storedProgress = getProgress();
    setBook(storedBook);
    setProgress(storedProgress);
  }, []);

  if (!book || !progress) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600">No reading plan found. Please upload a book first.</p>
      </div>
    );
  }

  const today = new Date().toISOString().split('T')[0];

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="bg-white rounded-2xl shadow-lg p-6">
        <div className="flex items-start gap-4">
          <div className="bg-indigo-100 p-3 rounded-lg">
            <Book className="size-8 text-indigo-600" />
          </div>
          <div className="flex-1">
            <h2 className="text-2xl font-bold mb-1">{book.title}</h2>
            <p className="text-gray-600">by {book.author}</p>
            <div className="flex gap-6 mt-3">
              <div>
                <p className="text-sm text-gray-500">Total Pages</p>
                <p className="font-bold">{book.totalPages}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Duration</p>
                <p className="font-bold">{progress.totalDays} days</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Avg. Pages/Day</p>
                <p className="font-bold">{Math.round(book.totalPages / progress.totalDays)}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Daily Plan */}
      <div className="bg-white rounded-2xl shadow-lg p-6">
        <div className="flex items-center gap-2 mb-6">
          <Calendar className="size-5 text-indigo-600" />
          <h3 className="font-bold text-lg">Daily Reading Schedule</h3>
        </div>

        <div className="space-y-3">
          {progress.dailyPages.map((day: any, index: number) => {
            const dayNumber = index + 1;
            const isCompleted = progress.completedDays.some((d: string) => {
              const date = new Date(book.uploadDate);
              date.setDate(date.getDate() + index);
              return d === date.toISOString().split('T')[0];
            });
            const isCurrent = progress.currentDay === dayNumber;
            const isPast = dayNumber < progress.currentDay;
            
            const date = new Date(book.uploadDate);
            date.setDate(date.getDate() + index);
            const dateStr = date.toLocaleDateString('en-US', { 
              month: 'short', 
              day: 'numeric',
              year: 'numeric'
            });

            return (
              <div
                key={dayNumber}
                className={`flex flex-col gap-3 p-4 rounded-lg border-2 transition-all ${
                  isCurrent
                    ? 'border-indigo-500 bg-indigo-50'
                    : isCompleted
                    ? 'border-green-200 bg-green-50'
                    : isPast
                    ? 'border-gray-200 bg-gray-50'
                    : 'border-gray-200 bg-white'
                }`}
              >
                <div className="flex items-center gap-4">
                  <div className="flex-shrink-0">
                    {isCompleted ? (
                      <div className="bg-green-500 rounded-full p-1">
                        <CheckCircle2 className="size-6 text-white" />
                      </div>
                    ) : (
                      <div className={`rounded-full p-1 ${isCurrent ? 'bg-indigo-500' : 'bg-gray-300'}`}>
                        <Circle className="size-6 text-white" />
                      </div>
                    )}
                  </div>

                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-bold">Day {dayNumber}</span>
                      {isCurrent && (
                        <span className="bg-indigo-600 text-white text-xs px-2 py-0.5 rounded-full">
                          Today
                        </span>
                      )}
                      <span className={`text-xs px-2 py-0.5 rounded-full ${
                        isCurrent ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-700'
                      }`}>
                        {day.theme}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600">{dateStr}</p>
                  </div>

                  <div className="text-right">
                    <p className="font-medium">Pages {day.start} - {day.end}</p>
                    <p className="text-sm text-gray-600">{day.pages} pages</p>
                  </div>
                </div>

                {/* Summary - only show for current and upcoming days */}
                {!isPast && day.summary && (
                  <div className="pl-14 pr-4">
                    <p className="text-sm text-gray-700 italic">{day.summary}</p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}