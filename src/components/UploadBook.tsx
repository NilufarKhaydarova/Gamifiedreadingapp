import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Upload, BookOpen, Calendar } from 'lucide-react';
import { saveBook, initializeProgress } from '../lib/storage';

export function UploadBook() {
  const navigate = useNavigate();
  const [step, setStep] = useState<'upload' | 'details'>('upload');
  const [bookContent, setBookContent] = useState('');
  const [formData, setFormData] = useState({
    title: '',
    author: '',
    totalPages: '',
    daysToComplete: '30',
  });

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const content = event.target?.result as string;
        setBookContent(content);
        setStep('details');
      };
      reader.readAsText(file);
    }
  };

  const handleTextUpload = () => {
    if (bookContent.trim()) {
      setStep('details');
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const book = {
      title: formData.title,
      author: formData.author,
      totalPages: parseInt(formData.totalPages),
      content: bookContent,
      uploadDate: new Date().toISOString(),
    };

    const daysToComplete = parseInt(formData.daysToComplete);
    
    // Save book and initialize progress
    saveBook(book);
    initializeProgress(book.totalPages, daysToComplete);
    
    navigate('/');
  };

  if (step === 'upload') {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-2xl shadow-lg p-8">
          <div className="text-center mb-8">
            <div className="bg-indigo-100 rounded-full p-6 w-fit mx-auto mb-4">
              <Upload className="size-12 text-indigo-600" />
            </div>
            <h2 className="text-2xl font-bold mb-2">Upload Your Book</h2>
            <p className="text-gray-600">
              Upload a text file or paste your book content to get started
            </p>
          </div>

          <div className="space-y-6">
            {/* File Upload */}
            <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-indigo-400 transition-colors">
              <input
                type="file"
                accept=".txt"
                onChange={handleFileUpload}
                className="hidden"
                id="file-upload"
              />
              <label
                htmlFor="file-upload"
                className="cursor-pointer flex flex-col items-center"
              >
                <BookOpen className="size-12 text-gray-400 mb-3" />
                <p className="font-medium text-gray-700 mb-1">
                  Click to upload a text file
                </p>
                <p className="text-sm text-gray-500">.txt files only</p>
              </label>
            </div>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-white text-gray-500">or</span>
              </div>
            </div>

            {/* Text Input */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Paste Book Content
              </label>
              <textarea
                value={bookContent}
                onChange={(e) => setBookContent(e.target.value)}
                placeholder="Paste the full text of your book here..."
                className="w-full h-48 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none"
              />
            </div>

            <button
              onClick={handleTextUpload}
              disabled={!bookContent.trim()}
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
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-2xl shadow-lg p-8">
        <div className="text-center mb-8">
          <div className="bg-indigo-100 rounded-full p-6 w-fit mx-auto mb-4">
            <Calendar className="size-12 text-indigo-600" />
          </div>
          <h2 className="text-2xl font-bold mb-2">Book Details</h2>
          <p className="text-gray-600">
            Tell us about your book to create a personalized reading plan
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Book Title *
            </label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g., War and Peace"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Author *
            </label>
            <input
              type="text"
              required
              value={formData.author}
              onChange={(e) => setFormData({ ...formData, author: e.target.value })}
              placeholder="e.g., Leo Tolstoy"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Total Pages *
            </label>
            <input
              type="number"
              required
              min="1"
              value={formData.totalPages}
              onChange={(e) => setFormData({ ...formData, totalPages: e.target.value })}
              placeholder="e.g., 1225"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Days to Complete *
            </label>
            <input
              type="number"
              required
              min="1"
              value={formData.daysToComplete}
              onChange={(e) => setFormData({ ...formData, daysToComplete: e.target.value })}
              placeholder="e.g., 30"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
            <p className="mt-2 text-sm text-gray-500">
              We'll divide your book into manageable daily reading goals
            </p>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setStep('upload')}
              className="flex-1 bg-gray-200 text-gray-700 px-6 py-3 rounded-lg hover:bg-gray-300 transition-colors"
            >
              Back
            </button>
            <button
              type="submit"
              className="flex-1 bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors"
            >
              Create Reading Plan
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
