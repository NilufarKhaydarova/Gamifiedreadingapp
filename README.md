# 🎯 Gamified Reading App

A comprehensive reading platform that transforms book reading into an engaging, gamified experience with AI-powered features, progress tracking, and cross-platform support.

![Version](https://img.shields.io/badge/version-0.1.0-blue)
![Status](https://img.shields.io/badge/status-beta-orange)
![Platform](https://img.shields.io/badge/platform-web--ios--android--macos-green)
![License](https://img.shields.io/badge/license-MIT-blue)

## ✨ **Features**

### **📚 Core Reading Experience**
- **Smart Book Upload**: Upload text files or paste content directly
- **Custom Reading Plans**: Set your own timeline (default: 30 days)
- **Progress Tracking**: Visual progress bars and daily goals
- **Local Storage**: All books saved securely in your browser

### **🎮 Gamification System**
- **XP & Leveling**: Earn 50 XP per completed reading day
- **Achievement Badges**: Unlock achievements for streaks and milestones
- **Streak Tracking**: Maintain consistency with daily check-ins
- **Leaderboards**: Compete with other readers *(coming soon)*

### **🤖 AI-Powered Features**
- **Voice Chat Bot**: Talk about books hands-free
- **Text Chat Interface**: Ask questions and discuss content
- **Book Analysis**: AI explains themes, characters, and plot
- **Reading Comprehension**: Test understanding through AI quizzes

### **🎧 Audio Features**
- **Text-to-Speech**: Listen to any book content
- **Playback Controls**: Play, pause, adjust speed (0.5x - 2.0x)
- **Chapter Navigation**: Jump between sections

### **📱 Cross-Platform Support**
- **Web App**: Modern React-based interface
- **Flutter Mobile App**: iOS, Android, and macOS support
- **Responsive Design**: Works seamlessly on all devices

---

## 🚀 **Quick Start**

### **Installation**
```bash
# Clone the repository
git clone https://github.com/NilufarKhaydarova/Gamifiedreadingapp.git

# Navigate to project
cd Gamifiedreadingapp

# Install dependencies
npm install

# Start development server
npm run dev
```

Open `http://localhost:5173` in your browser.

### **5-Minute Setup**
1. **Onboarding** → Complete welcome flow (30 seconds)
2. **Upload Book** → Add your first book (1 minute)
3. **Set Schedule** → Choose completion timeline (30 seconds)
4. **Start Reading** → Track daily progress (ongoing)

**📖 Detailed Guide:** [Quick Start Guide](./QUICK_START.md)

---

## 📖 **Documentation**

### **🔥 Essential Reading**
- 🚀 [**Quick Start Guide**](./QUICK_START.md) - Get started in 5 minutes
- 📚 [**Features Overview**](./FEATURES.md) - Complete feature documentation
- 🛠️ [**Technical Guide**](./TECHNICAL_GUIDE.md) - Development & setup
- 🔌 [**API Reference**](./API_REFERENCE.md) - Function documentation

### **Project Structure**
```
Gamifiedreadingapp/
├── src/                    # React web app
│   ├── components/         # UI components
│   ├── lib/               # Utilities & services
│   └── routes.ts          # App navigation
├── booklify/              # Flutter mobile app
│   ├── lib/              # Dart source code
│   ├── android/          # Android config
│   ├── ios/              # iOS config
│   └── macos/            # macOS config
├── supabase/             # Database migrations
├── FEATURES.md           # Feature documentation
├── TECHNICAL_GUIDE.md    # Technical documentation
├── API_REFERENCE.md      # API documentation
└── QUICK_START.md        # Getting started guide
```

---

## 🎯 **How It Works**

### **User Journey**
1. **Onboarding** → Quick welcome and setup
2. **Book Upload** → Add books as text files
3. **Reading Plan** → Set custom completion timeline
4. **Daily Reading** → Track progress and earn XP
5. **Achievements** → Unlock badges for milestones
6. **AI Features** → Discuss books with AI assistant

### **Gamification System**
```typescript
// Daily Progress
Mark Day Complete → Earn 50 XP → Level Up

// Achievement Examples
First Steps     → Complete day 1
Week Warrior    → 7-day streak
Monthly Master  → 30-day streak
Bookworm        → Read multiple books
```

---

## 🛠️ **Tech Stack**

### **Frontend (Web)**
- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **Radix UI** - Component library
- **Lucide React** - Icons

### **Mobile App**
- **Flutter** - Cross-platform framework
- **Dart** - Programming language
- **Platform Support** - iOS, Android, macOS

### **Backend & Database**
- **Supabase** - Backend services
- **PostgreSQL** - Database
- **Vector DB** - AI search capabilities

### **AI Integration**
- **OpenAI API** - GPT models *(planned)*
- **RAG System** - Retrieval-Augmented Generation
- **Langfuse** - AI observability

---

## 📊 **Current Status**

### **✅ Completed Features**
- [x] Book upload system (file & text)
- [x] Reading progress tracking
- [x] Achievement system
- [x] XP and leveling system
- [x] Basic AI chat interface
- [x] Audio player foundation
- [x] Onboarding flow
- [x] Flutter mobile app structure

### **🚧 In Development**
- [ ] Advanced AI integration
- [ ] Database backend setup
- [ ] Social features
- [ ] Multi-book library
- [ ] Cross-device sync

### **🔮 Planned Features**
- [ ] Leaderboards
- [ ] Reading statistics dashboard
- [ ] Book recommendations
- [ ] Offline mode
- [ ] Push notifications

---

## 🤖 **AI Features**

### **Current Implementation**
- **Basic Chat Interface**: Text-based AI conversations
- **Voice Chat Foundation**: Speech recognition setup
- **Book Analysis**: Content understanding

### **Planned Enhancements**
- **Advanced RAG**: Context-aware responses
- **Personality Modes**: Different AI discussion styles
- **Reading Coach**: Personalized reading tips
- **Quiz Generator**: Auto-generated comprehension tests

---

## 📱 **Mobile App Setup**

### **Flutter Development**
```bash
cd booklify
flutter pub get
flutter run
```

### **Platform-Specific Builds**
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# macOS
flutter run -d macos
```

---

## 🔧 **Configuration**

### **Environment Variables**
Create `.env` file:
```env
VITE_API_URL=your_api_url
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_OPENAI_API_KEY=your_openai_key
```

### **Customization**
- **Reading Plan Length**: Modify default days
- **XP Rewards**: Adjust experience points
- **Achievement Criteria**: Custom requirements
- **Theme Colors**: Personalize appearance

**🛠️ Details:** [Technical Guide](./TECHNICAL_GUIDE.md)

---

## 🧪 **Testing**

```bash
# Run tests
npm test

# Test coverage
npm run test:coverage

# E2E tests
npm run test:e2e
```

---

## 📈 **Performance**

### **Optimization Features**
- **Code Splitting**: Lazy-loaded components
- **Image Optimization**: WebP format with lazy loading
- **Bundle Analysis**: Size monitoring
- **LocalStorage**: Fast data access

### **Browser Support**
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

---

## 🔒 **Security**

### **Best Practices**
- ✅ Environment variables for sensitive data
- ✅ Input validation on client and server
- ✅ HTTPS for all API calls
- ✅ No hardcoded API keys
- ✅ Regular dependency updates

---

## 🤝 **Contributing**

We welcome contributions! Please see our contributing guidelines:

1. **Fork** the repository
2. **Create** a feature branch
3. **Commit** your changes
4. **Push** to the branch
5. **Open** a Pull Request

**📖 Development Guide:** [Technical Guide](./TECHNICAL_GUIDE.md)

---

## 📝 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 **Acknowledgments**

- **Design**: Original project from [Figma Make](https://www.figma.com/design/MoPJUawvucF2hOVWmrDnLK/Gamified-Reading-App)
- **UI Components**: [shadcn/ui](https://ui.shadcn.com/) - MIT license
- **Images**: [Unsplash](https://unsplash.com) - Unsplash license
- **Icons**: [Lucide](https://lucide.dev) - ISC license

---

## 📧 **Contact & Support**

### **Getting Help**
- 📖 [Documentation](./FEATURES.md)
- 🐛 [Issue Tracker](https://github.com/NilufarKhaydarova/Gamifiedreadingapp/issues)
- 💬 [Discussions](https://github.com/NilufarKhaydarova/Gamifiedreadingapp/discussions)

### **Connect**
- 👤 **Author**: Nilufar Khaydarova
- 📧 **Email**: support@gamifiedreading.app
- 🔗 **GitHub**: [@NilufarKhaydarova](https://github.com/NilufarKhaydarova)

---

## 🌟 **Star History**

[![Star History Chart](https://api.star-history.com/svg?repos=NilufarKhaydarova/Gamifiedreadingapp&type=Date)](https://star-history.com/#NilufarKhaydarova/Gamifiedreadingapp&Date)

---

## 🚀 **Roadmap**

### **Version 0.2.0 (Next Release)**
- [ ] Advanced AI integration
- [ ] Multi-book library
- [ ] Enhanced gamification
- [ ] Social features

### **Version 1.0.0 (Major Release)**
- [ ] Complete mobile app
- [ ] Cross-device sync
- [ ] Offline mode
- [ ] Full database backend

---

**Made with ❤️ for book lovers everywhere**

---

*Last Updated: March 15, 2026 • Version: 0.1.0 • Status: Beta*

**🚀 Ready to transform your reading experience?**

```bash
npm install && npm run dev
```

**Happy Reading!** 📚✨