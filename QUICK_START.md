# 🚀 Quick Start Guide

## **⚡ 5-Minute Setup**

### **Step 1: Installation**
```bash
# Clone the repository
git clone https://github.com/NilufarKhaydarova/Gamifiedreadingapp.git

# Navigate to project
cd Gamifiedreadingapp

# Install dependencies
npm install
```

### **Step 2: Start Development Server**
```bash
npm run dev
```
Open: `http://localhost:5173`

### **Step 3: Start Reading**
1. **Onboarding** → Complete welcome flow (30 seconds)
2. **Upload Book** → Add your first book (1 minute)
3. **Set Schedule** → Choose completion timeline (30 seconds)
4. **Start Reading** → Track daily progress (ongoing)

---

## **📱 App Walkthrough**

### **First Launch**
When you first open the app, you'll see the **Onboarding Screen**:
- Welcome message
- Feature overview
- "Get Started" button

### **Upload Your First Book**
1. Click **"Upload Book"** in the dashboard
2. Choose your book source:
   - **File Upload**: Select a `.txt` file
   - **Manual Entry**: Paste text directly
3. Fill in book details:
   - Title *(required)*
   - Author *(required)*
   - Total Pages *(required)*
   - Days to Complete *(optional, default: 30)*
4. Click **"Save Book"**

### **Reading Dashboard**
After uploading, you'll see your **Dashboard**:
- 📖 **Current Book**: Title, author, progress
- 📊 **Reading Progress**: Visual progress bar
- ✅ **Daily Check-in**: Mark days complete
- 🎯 **XP & Level**: Track your gamification progress

### **Complete Daily Reading**
1. Read your daily target
2. Click **"Mark Day Complete"**
3. Earn **50 XP** automatically
4. Watch your **streak grow** 🔥

---

## **🎮 Core Features**

### **📚 Book Management**
- **Upload**: Add books as text files
- **Storage**: Books saved in browser
- **Multiple Books**: Switch between books *(coming soon)*

### **📊 Progress Tracking**
- **Daily Goals**: Automatic targets based on your plan
- **Visual Progress**: See how far you've come
- **Streak Tracking**: Maintain reading consistency
- **XP System**: Earn points for completing days

### **🏆 Achievements**
Unlock achievements by:
- ✅ Reading consistently (streaks)
- 📚 Completing books
- 🎯 Hitting milestones
- 💬 Participating in AI discussions

### **🤖 AI Features**
- **Voice Chat**: Talk about books hands-free
- **Text Chat**: Ask questions about content
- **Book Analysis**: AI explains themes and characters

### **🎧 Audio Player**
- **Text-to-Speech**: Listen to any book
- **Speed Control**: Adjust reading speed (0.5x - 2.0x)
- **Playback Controls**: Play, pause, skip sections

---

## **🎯 Typical User Journey**

### **Day 1: Getting Started**
1. **Onboarding** (2 min)
2. **Upload Book** (3 min)
3. **Set 30-Day Plan** (1 min)
4. **Read Day 1** (15-30 min)
5. **Mark Complete** → Earn 50 XP 🎉

### **Day 7: Week Warrior**
1. **Maintain Streak** → 7 days
2. **Unlock "Week Warrior" Achievement** 🏆
3. **Chat with AI** about the book
4. **Continue Reading** → Day 7/30

### **Day 30: Completion**
1. **Finish Final Day**
2. **Unlock "Monthly Master" Achievement** 🏆
3. **Upload New Book** → Continue journey
4. **Review Stats** → See total progress

---

## **🔧 Quick Configuration**

### **Customize Your Experience**

#### **Change Reading Plan Length**
```typescript
// In UploadBook component
<input
  type="number"
  name="daysToComplete"
  defaultValue="30"  // Change this!
/>
```

#### **Adjust XP Rewards**
```typescript
// In Dashboard component
addXP(50);  // Change 50 to any number
```

#### **Modify Achievement Criteria**
```typescript
// In Achievements component
unlocked: streak >= 7,  // Change 7 to any number
```

---

## **🎨 UI Customization**

### **Change Theme Colors**
Edit `tailwind.config.js`:
```javascript
theme: {
  extend: {
    colors: {
      primary: {
        500: '#6366f1',  // Change this color
        600: '#4f46e5',  // And this one
      }
    }
  }
}
```

### **Customize Fonts**
Edit `index.html`:
```html
<style>
  body {
    font-family: 'Your Font', sans-serif;
  }
</style>
```

---

## **🐛 Troubleshooting**

### **Common Issues**

#### **❌ "Book not uploading"**
**Solution:**
- Ensure file is `.txt` format
- Check file size (< 5MB recommended)
- Try manual text entry instead

#### **❌ "Progress not saving"**
**Solution:**
- Check browser localStorage is enabled
- Clear browser cache and try again
- Ensure you're not in private/incognito mode

#### **❌ "Audio not working"**
**Solution:**
- Check browser supports Web Speech API
- Ensure microphone permissions are granted
- Try a different browser (Chrome recommended)

#### **❌ "AI chat not responding"**
**Solution:**
- Check internet connection
- Verify API keys are configured
- See [API Reference](./API_REFERENCE.md) for setup

---

## **📊 Understanding Your Progress**

### **XP & Leveling System**
- **Base XP**: 0 (starting level)
- **XP per Day**: 50 (daily completion)
- **Level Up**: Every 100 XP
- **Example:** 2 days = 100 XP = Level 2

### **Achievement Tracking**
- **Streak Achievements**: Based on consecutive days
- **Reading Achievements**: Based on books completed
- **Social Achievements**: Based on AI interactions

### **Progress Calculations**
```typescript
// Daily reading target
dailyPages = totalPages / totalDays

// Progress percentage
progressPercent = (currentDay / totalDays) * 100

// Streak calculation
streak = consecutive days in completedDays array
```

---

## **🎓 Tips & Tricks**

### **Maximize Your XP**
1. **Consistent Reading**: Maintain streaks
2. **AI Interaction**: Chat about books regularly
3. **Complete Plans**: Finish reading schedules
4. **Quick Reader**: Complete books faster

### **Stay Motivated**
1. **Set Realistic Goals**: Start with 30-day plans
2. **Track Streaks**: Focus on daily consistency
3. **Use Audio**: Listen when you can't read
4. **Chat with AI**: Deepen understanding

### **Power User Features**
- **Keyboard Shortcuts**: Press 'Space' to mark complete
- **Quick Upload**: Drag & drop text files
- **Audio Mode**: Listen while commuting
- **AI Discussion**: Prepare for book clubs

---

## **📱 Mobile Usage**

### **Flutter App Setup**
```bash
cd booklify
flutter pub get
flutter run
```

### **Mobile Features**
- **Offline Reading**: Books stored locally
- **Push Notifications**: Daily reading reminders *(coming soon)*
- **Voice Commands**: Hands-free operation
- **Cross-Device Sync**: Progress syncs across devices *(coming soon)*

---

## **🚀 Next Steps**

1. **Upload Your First Book** → Start your journey
2. **Set Realistic Goals** → Choose achievable timeline
3. **Build Habits** → Read consistently every day
4. **Engage with AI** → Deepen your understanding
5. **Unlock Achievements** → Gamify your progress

---

## **📚 Additional Resources**

- [📖 Full Features Guide](./FEATURES.md)
- [🛠️ Technical Documentation](./TECHNICAL_GUIDE.md)
- [🔌 API Reference](./API_REFERENCE.md)
- [🐛 Issue Tracker](https://github.com/NilufarKhaydarova/Gamifiedreadingapp/issues)

---

## **💬 Getting Help**

**Questions? Issues? Suggestions?**
- 📧 Email Support: support@gamifiedreading.app
- 💬 GitHub Issues: [Create Issue](https://github.com/NilufarKhaydarova/Gamifiedreadingapp/issues)
- 📖 Documentation: [Full Docs](./FEATURES.md)

---

**Ready to start your gamified reading journey?** 🚀

```bash
npm run dev
```

Then open: `http://localhost:5173`

**Happy Reading!** 📚✨

---

*Last Updated: March 15, 2026*
*Version: 0.1.0 (Beta)*
*Status: Active Development*