import { useState, useEffect, useRef } from 'react';
import { getStoredBook, getProgress } from '../lib/storage';
import { Send, BookOpen, Brain, Users, HelpCircle, Loader2 } from 'lucide-react';
import {
  companionRetrieve,
  askCompanion,
  fallbackResponse,
  makeBookId,
  episodeIndexFromProgress,
  countChunks,
} from '../lib/rag';
import type { ChatMode, ConversationMessage, CompanionRetrievalContext } from '../lib/rag';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export function ChatBot() {
  const [book, setBook] = useState<any>(null);
  const [progress, setProgress] = useState<any>(null);
  const [mode, setMode] = useState<ChatMode>('discussion');
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [totalChunks, setTotalChunks] = useState(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const storedBook = getStoredBook();
    const storedProgress = getProgress();
    setBook(storedBook);
    setProgress(storedProgress);

    if (storedBook) {
      setMessages([
        {
          id: '1',
          role: 'assistant',
          content: getWelcomeMessage('discussion', storedBook),
          timestamp: new Date(),
        },
      ]);

      // Load total chunks for progress display (non-blocking)
      const bookId = makeBookId(storedBook.title, storedBook.uploadDate);
      countChunks(bookId).then(setTotalChunks).catch(() => {});
    }
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleModeChange = (newMode: ChatMode) => {
    setMode(newMode);
    setMessages([
      {
        id: Date.now().toString(),
        role: 'assistant',
        content: getWelcomeMessage(newMode, book),
        timestamp: new Date(),
      },
    ]);
  };

  const handleSend = async () => {
    if (!input.trim() || !book || isLoading) return;

    const userText = input.trim();
    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: userText,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    // Build conversation history for Claude (skip welcome message)
    const history: ConversationMessage[] = messages
      .slice(1)
      .map((m) => ({ role: m.role, content: m.content }));

    let aiText: string;
    try {
      const bookId = makeBookId(book.title, book.uploadDate);
      const currentEpisodeIndex =
        progress && totalChunks > 0
          ? episodeIndexFromProgress(
              progress.currentDay,
              progress.dailyPages,
              book.totalPages,
              totalChunks,
            )
          : 0;

      // Retrieve RAG context — graceful fallback if no embeddings yet
      let context: CompanionRetrievalContext;
      try {
        context = await companionRetrieve(userText, bookId, currentEpisodeIndex);
      } catch {
        context = { relevant: [], callbacks: [] };
      }

      aiText = await askCompanion(
        userText,
        mode,
        context,
        book.title,
        book.author,
        currentEpisodeIndex,
        totalChunks,
        history,
      );
    } catch (err) {
      console.error('[ChatBot] AI error:', err);
      aiText = fallbackResponse(mode, book.title);
    }

    setIsLoading(false);
    setMessages((prev) => [
      ...prev,
      {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: aiText,
        timestamp: new Date(),
      },
    ]);
  };

  if (!book) {
    return (
      <div className="text-center py-16">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md mx-auto">
          <BookOpen className="size-12 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-600">Please upload a book first to start chatting.</p>
        </div>
      </div>
    );
  }

  const modes = [
    {
      id: 'discussion' as ChatMode,
      name: 'Book Club',
      icon: Users,
      color: 'purple',
      description: 'Spoiler-free discussions',
    },
    {
      id: 'socratic' as ChatMode,
      name: 'Socratic',
      icon: Brain,
      color: 'blue',
      description: 'Deep learning questions',
    },
    {
      id: 'quiz' as ChatMode,
      name: 'Quiz',
      icon: HelpCircle,
      color: 'green',
      description: 'Test your knowledge',
    },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-4">
      {/* Mode Selector */}
      <div className="bg-white rounded-2xl shadow-lg p-4">
        <div className="flex gap-2 overflow-x-auto">
          {modes.map((m) => {
            const Icon = m.icon;
            const isActive = mode === m.id;
            return (
              <button
                key={m.id}
                onClick={() => handleModeChange(m.id)}
                className={`flex items-center gap-2 px-4 py-3 rounded-lg transition-all whitespace-nowrap ${
                  isActive
                    ? `bg-${m.color}-100 border-2 border-${m.color}-500`
                    : 'bg-gray-50 border-2 border-transparent hover:border-gray-300'
                }`}
              >
                <Icon className={`size-5 ${isActive ? `text-${m.color}-600` : 'text-gray-600'}`} />
                <div className="text-left">
                  <p className={`font-medium text-sm ${isActive ? `text-${m.color}-900` : 'text-gray-900'}`}>
                    {m.name}
                  </p>
                  <p className="text-xs text-gray-500">{m.description}</p>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Chat Messages */}
      <div className="bg-white rounded-2xl shadow-lg p-6 h-[600px] flex flex-col">
        <div className="flex-1 overflow-y-auto mb-4 space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[80%] rounded-lg px-4 py-3 ${
                  message.role === 'user'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-900'
                }`}
              >
                <p className="whitespace-pre-wrap">{message.content}</p>
                <p
                  className={`text-xs mt-1 ${
                    message.role === 'user' ? 'text-indigo-200' : 'text-gray-500'
                  }`}
                >
                  {message.timestamp.toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
            </div>
          ))}

          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-gray-100 rounded-lg px-4 py-3 flex items-center gap-2 text-gray-500">
                <Loader2 className="size-4 animate-spin" />
                <span className="text-sm">Thinking…</span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
            placeholder={`Ask about ${book.title}…`}
            disabled={isLoading}
            className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent disabled:bg-gray-50"
          />
          <button
            onClick={handleSend}
            disabled={!input.trim() || isLoading}
            className="bg-indigo-600 text-white px-6 py-3 rounded-lg hover:bg-indigo-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {isLoading ? <Loader2 className="size-5 animate-spin" /> : <Send className="size-5" />}
          </button>
        </div>
      </div>
    </div>
  );
}

function getWelcomeMessage(mode: ChatMode, book: any): string {
  const messages: Record<ChatMode, string> = {
    discussion: `Welcome to the Book Club discussion for "${book.title}"! 🎭\n\nI'm here to discuss themes, characters, and ideas without spoiling anything beyond your current reading progress. What would you like to explore?`,
    socratic: `Welcome to Socratic Learning for "${book.title}"! 🧠\n\nI'll help deepen your understanding through thoughtful questions. Instead of giving you answers, I'll guide you to discover insights yourself. Ready to explore?`,
    quiz: `Welcome to Quiz Mode for "${book.title}"! 📝\n\nI'll test your comprehension of what you've read so far with questions tailored to your progress. Let me know when you're ready, or ask me for a quiz!`,
  };
  return messages[mode];
}
