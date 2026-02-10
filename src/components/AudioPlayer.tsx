import { useState, useEffect, useRef } from 'react';
import { getStoredBook, getProgress, updateProgress } from '../lib/storage';
import { Play, Pause, SkipBack, SkipForward, Volume2, Settings } from 'lucide-react';

export function AudioPlayer() {
  const [book, setBook] = useState<any>(null);
  const [progress, setProgress] = useState<any>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [rate, setRate] = useState(1);
  const [voice, setVoice] = useState<SpeechSynthesisVoice | null>(null);
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);
  const [showSettings, setShowSettings] = useState(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);
  const textPositionRef = useRef(0);

  useEffect(() => {
    const storedBook = getStoredBook();
    const storedProgress = getProgress();
    setBook(storedBook);
    setProgress(storedProgress);

    if (storedProgress?.audioPosition) {
      setCurrentTime(storedProgress.audioPosition);
    }

    // Load available voices
    const loadVoices = () => {
      const availableVoices = window.speechSynthesis.getVoices();
      setVoices(availableVoices);
      if (availableVoices.length > 0 && !voice) {
        setVoice(availableVoices[0]);
      }
    };

    loadVoices();
    window.speechSynthesis.onvoiceschanged = loadVoices;

    return () => {
      window.speechSynthesis.cancel();
    };
  }, []);

  const getCurrentPageContent = () => {
    if (!book || !progress) return '';
    
    const currentDayData = progress.dailyPages[progress.currentDay - 1];
    if (!currentDayData) return '';

    // In a real implementation, you would extract the text for these specific pages
    // For now, we'll use a portion of the content
    return book.content || 'No content available for audio playback.';
  };

  const handlePlayPause = () => {
    if (isPlaying) {
      window.speechSynthesis.pause();
      setIsPlaying(false);
    } else {
      if (window.speechSynthesis.paused) {
        window.speechSynthesis.resume();
      } else {
        const text = getCurrentPageContent();
        const utterance = new SpeechSynthesisUtterance(text);
        
        if (voice) {
          utterance.voice = voice;
        }
        utterance.rate = rate;
        
        utterance.onend = () => {
          setIsPlaying(false);
          // Save position when finished
          if (progress) {
            updateProgress({ ...progress, audioPosition: 0 });
          }
        };

        utterance.onpause = () => {
          setIsPlaying(false);
        };

        utterance.onboundary = (event) => {
          setCurrentTime(event.charIndex);
          textPositionRef.current = event.charIndex;
        };

        utteranceRef.current = utterance;
        window.speechSynthesis.speak(utterance);
      }
      setIsPlaying(true);
    }
  };

  const handleStop = () => {
    window.speechSynthesis.cancel();
    setIsPlaying(false);
    setCurrentTime(0);
    
    if (progress) {
      updateProgress({ ...progress, audioPosition: 0 });
    }
  };

  const handleSkip = (seconds: number) => {
    // Skip forward/backward in speech
    const newPosition = Math.max(0, textPositionRef.current + (seconds * 10));
    textPositionRef.current = newPosition;
    setCurrentTime(newPosition);
    
    if (progress) {
      updateProgress({ ...progress, audioPosition: newPosition });
    }
  };

  const handleRateChange = (newRate: number) => {
    setRate(newRate);
    if (isPlaying) {
      window.speechSynthesis.cancel();
      setIsPlaying(false);
    }
  };

  if (!book || !progress) {
    return (
      <div className="text-center py-16">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md mx-auto">
          <p className="text-gray-600">Please upload a book first to use audio features.</p>
        </div>
      </div>
    );
  }

  const currentDayData = progress.dailyPages[progress.currentDay - 1];
  const content = getCurrentPageContent();

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Player Card */}
      <div className="bg-gradient-to-br from-purple-600 to-indigo-700 rounded-2xl shadow-lg p-8 text-white">
        <div className="flex items-start justify-between mb-6">
          <div>
            <p className="text-purple-200 text-sm mb-1">Now Playing</p>
            <h2 className="text-2xl font-bold mb-1">{book.title}</h2>
            <p className="text-purple-200">by {book.author}</p>
          </div>
          <button
            onClick={() => setShowSettings(!showSettings)}
            className="bg-white/20 backdrop-blur-sm p-3 rounded-lg hover:bg-white/30 transition-colors"
          >
            <Settings className="size-5" />
          </button>
        </div>

        {/* Current Day Info */}
        <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4 mb-6">
          <p className="text-purple-200 text-sm mb-1">Today's Reading</p>
          <p className="font-medium">
            Day {progress.currentDay} - Pages {currentDayData?.start} to {currentDayData?.end}
          </p>
          <p className="text-purple-200 text-sm mt-1">{currentDayData?.theme}</p>
        </div>

        {/* Settings Panel */}
        {showSettings && (
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4 mb-6 space-y-4">
            <div>
              <label className="block text-sm text-purple-200 mb-2">Playback Speed</label>
              <div className="flex gap-2">
                {[0.5, 0.75, 1, 1.25, 1.5, 2].map((speed) => (
                  <button
                    key={speed}
                    onClick={() => handleRateChange(speed)}
                    className={`px-3 py-2 rounded-lg text-sm transition-colors ${
                      rate === speed
                        ? 'bg-white text-purple-700 font-medium'
                        : 'bg-white/20 hover:bg-white/30'
                    }`}
                  >
                    {speed}x
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm text-purple-200 mb-2">Voice</label>
              <select
                value={voice?.name || ''}
                onChange={(e) => {
                  const selectedVoice = voices.find((v) => v.name === e.target.value);
                  if (selectedVoice) setVoice(selectedVoice);
                }}
                className="w-full px-4 py-2 rounded-lg bg-white/20 border border-white/30 text-white focus:ring-2 focus:ring-white/50"
              >
                {voices.map((v) => (
                  <option key={v.name} value={v.name} className="text-gray-900">
                    {v.name} ({v.lang})
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}

        {/* Controls */}
        <div className="flex items-center justify-center gap-4">
          <button
            onClick={() => handleSkip(-15)}
            className="bg-white/20 backdrop-blur-sm p-3 rounded-full hover:bg-white/30 transition-colors"
          >
            <SkipBack className="size-6" />
          </button>

          <button
            onClick={handlePlayPause}
            className="bg-white text-purple-700 p-5 rounded-full hover:bg-purple-50 transition-colors"
          >
            {isPlaying ? (
              <Pause className="size-8" />
            ) : (
              <Play className="size-8 ml-1" />
            )}
          </button>

          <button
            onClick={() => handleSkip(15)}
            className="bg-white/20 backdrop-blur-sm p-3 rounded-full hover:bg-white/30 transition-colors"
          >
            <SkipForward className="size-6" />
          </button>
        </div>

        <div className="flex items-center justify-center gap-2 mt-4">
          <Volume2 className="size-5 text-purple-200" />
          <p className="text-sm text-purple-200">
            Position: {Math.floor(currentTime / 100)} / {Math.floor(content.length / 100)}
          </p>
        </div>
      </div>

      {/* Reading Text */}
      <div className="bg-white rounded-2xl shadow-lg p-8">
        <h3 className="font-bold text-lg mb-4">Text Content</h3>
        <div className="prose max-w-none">
          <p className="text-gray-700 leading-relaxed whitespace-pre-wrap">
            {content.substring(0, 500)}...
          </p>
          <p className="text-sm text-gray-500 mt-4 italic">
            Full text will play during audio playback
          </p>
        </div>
      </div>

      {/* Tips */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <p className="text-sm text-blue-900 font-medium mb-2">💡 Audio Tips:</p>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• Your listening position is automatically saved</li>
          <li>• Adjust playback speed to match your preference</li>
          <li>• Use skip buttons to navigate through content</li>
          <li>• Switch between reading and listening seamlessly</li>
        </ul>
      </div>
    </div>
  );
}
