# 🔌 API Reference & Function Documentation

## 📋 **Complete Function Catalog**

### **📚 Storage Functions (`src/lib/storage.ts`)**

#### **Book Management**

##### `saveBook(book: Book): void`
**Description:** Saves a book to localStorage

**Parameters:**
```typescript
interface Book {
  title: string;           // Book title
  author: string;          // Author name
  totalPages: number;      // Total page count
  content: string;         // Book text content
  uploadDate: string;      // ISO timestamp
}
```

**Usage:**
```typescript
const book = {
  title: "The Great Gatsby",
  author: "F. Scott Fitzgerald",
  totalPages: 180,
  content: "In my younger and more vulnerable years...",
  uploadDate: new Date().toISOString()
};

saveBook(book);
```

---

##### `getStoredBook(): Book | null`
**Description:** Retrieves the currently stored book

**Returns:** `Book object or null`

**Usage:**
```typescript
const currentBook = getStoredBook();
if (currentBook) {
  console.log(`Reading: ${currentBook.title}`);
}
```

---

##### `getStoredBooks(): Book[]`
**Description:** Gets all stored books from localStorage

**Returns:** `Array of Book objects`

**Usage:**
```typescript
const allBooks = getStoredBooks();
console.log(`Total books: ${allBooks.length}`);
```

---

#### **Progress Management**

##### `initializeProgress(totalDays: number): Progress`
**Description:** Creates a new progress tracking object

**Parameters:**
- `totalDays`: Number of days to complete the reading plan

**Returns:** `Progress object`

```typescript
interface Progress {
  currentDay: number;        // Current day in plan (starts at 1)
  totalDays: number;         // Total days in reading plan
  completedDays: string[];   // Array of ISO date strings
  xp: number;                // Experience points
  level: number;             // Current level
}
```

**Usage:**
```typescript
const progress = initializeProgress(30);
console.log(progress); // { currentDay: 1, totalDays: 30, completedDays: [], xp: 0, level: 1 }
```

---

##### `getProgress(): Progress | null`
**Description:** Retrieves current reading progress

**Returns:** `Progress object or null`

**Usage:**
```typescript
const progress = getProgress();
if (progress) {
  console.log(`Day ${progress.currentDay} of ${progress.totalDays}`);
}
```

---

##### `updateProgress(newProgress: Progress): void`
**Description:** Updates progress in localStorage

**Parameters:**
- `newProgress`: Updated progress object

**Usage:**
```typescript
const currentProgress = getProgress();
currentProgress.currentDay = 5;
currentProgress.xp = 200;
updateProgress(currentProgress);
```

---

#### **XP & Leveling System**

##### `addXP(amount: number): void`
**Description:** Adds experience points and checks for level up

**Parameters:**
- `amount`: Number of XP to add

**Side Effects:**
- Updates XP in localStorage
- Automatically levels up if threshold reached
- Stores new level in localStorage

**Usage:**
```typescript
addXP(50); // Add 50 XP (typical daily completion reward)
```

---

##### `getXP(): number`
**Description:** Gets current XP total

**Returns:** `Current XP points`

**Usage:**
```typescript
const currentXP = getXP();
console.log(`Current XP: ${currentXP}`);
```

---

##### `getLevel(): number`
**Description:** Gets current user level

**Returns:** `Current level`

**Usage:**
```typescript
const level = getLevel();
console.log(`Level ${level}`);
```

---

##### `getXPForNextLevel(): number`
**Description:** Calculates XP needed for next level

**Returns:** `XP required to level up`

**Formula:** `currentLevel * 100`

**Usage:**
```typescript
const xpNeeded = getXPForNextLevel();
console.log(`Need ${xpNeeded} XP to reach level ${getLevel() + 1}`);
```

---

### **🎯 Component Functions**

#### **Dashboard Component**

##### `handleMarkComplete(): void`
**Description:** Marks current day as complete and awards XP

**Side Effects:**
- Adds current date to completedDays array
- Increments currentDay counter
- Awards 50 XP
- Updates localStorage

**Usage:**
```typescript
// In Dashboard component
<button onClick={handleMarkComplete}>
  Mark Today Complete
</button>
```

---

#### **UploadBook Component**

##### `handleFileUpload(event: React.ChangeEvent<HTMLInputElement>): void`
**Description:** Processes uploaded text file

**Parameters:**
- `event`: File input change event

**Side Effects:**
- Reads file content
- Stores content in state
- Advances to details step

**Usage:**
```typescript
<input
  type="file"
  accept=".txt"
  onChange={handleFileUpload}
/>
```

---

##### `handleTextUpload(): void`
**Description:** Validates and processes manually entered text

**Validation:**
- Checks if content is not empty
- Trims whitespace

**Usage:**
```typescript
<button onClick={handleTextUpload}>
  Use Manual Text Entry
</button>
```

---

##### `handleSubmit(event: React.FormEvent): void`
**Description:** Saves book with metadata and initializes progress

**Parameters:**
- `event`: Form submit event

**Creates:**
- Book object with metadata
- Progress tracking object
- localStorage entries

**Usage:**
```typescript
<form onSubmit={handleSubmit}>
  <input name="title" required />
  <input name="author" required />
  <input name="totalPages" type="number" required />
  <input name="daysToComplete" type="number" defaultValue="30" />
  <button type="submit">Save Book</button>
</form>
```

---

#### **Achievements Component**

##### `calculateStreak(completedDays: string[]): number`
**Description:** Calculates current reading streak from completed days

**Parameters:**
- `completedDays`: Array of ISO date strings

**Returns:** `Current streak in days`

**Algorithm:**
- Sorts dates chronologically
- Counts consecutive days
- Handles day gaps

**Usage:**
```typescript
const completedDates = ['2026-03-01', '2026-03-02', '2026-03-03'];
const streak = calculateStreak(completedDates);
console.log(streak); // 3
```

---

##### `checkUnlockStatus(achievement: Achievement, progress: Progress): boolean`
**Description:** Determines if an achievement is unlocked

**Parameters:**
- `achievement`: Achievement object to check
- `progress`: Current user progress

**Achievement Types:**
- `first-day`: 1+ completed days
- `week-warrior`: 7+ day streak
- `dedicated-reader`: 14+ day streak
- `monthly-master`: 30+ day streak

**Returns:** `true if unlocked, false otherwise`

**Usage:**
```typescript
const achievement = {
  id: 'week-warrior',
  title: 'Week Warrior',
  target: 7
};

const isUnlocked = checkUnlockStatus(achievement, userProgress);
```

---

### **🤖 AI Integration Functions**

#### **Voice Chat Bot**

##### `handleVoiceInput(audioBlob: Blob): Promise<string>`
**Description:** Processes voice input and converts to text

**Parameters:**
- `audioBlob`: Audio data from microphone

**Returns:** `Transcribed text string`

**Usage:**
```typescript
const audioBlob = await microphoneRecorder.stop();
const transcription = await handleVoiceInput(audioBlob);
```

---

##### `generateAIResponse(userMessage: string, bookContent: string): Promise<string>`
**Description:** Generates AI response about book content

**Parameters:**
- `userMessage`: User's question or comment
- `bookContent`: Context from the book

**Returns:** `AI-generated response`

**Usage:**
```typescript
const response = await generateAIResponse(
  "What's the main theme?",
  currentBook.content
);
```

---

#### **Text Chat Bot**

##### `handleChatMessage(message: string): void`
**Description:** Processes user chat message

**Parameters:**
- `message`: User's text message

**Side Effects:**
- Adds user message to chat history
- Triggers AI response generation
- Updates chat display

**Usage:**
```typescript
<input
  type="text"
  onSubmit={(e) => {
    handleChatMessage(e.target.value);
    e.target.value = '';
  }}
/>
```

---

### **🎧 Audio Player Functions**

##### `handleTextToSpeech(text: string): void`
**Description:** Converts text to speech using Web Speech API

**Parameters:**
- `text`: Text content to speak

**Usage:**
```typescript
<button onClick={() => handleTextToSpeech(bookContent)}>
  Play Audio
</button>
```

---

##### `handlePlayPause(): void`
**Description:** Toggles audio playback

**Usage:**
```typescript
<button onClick={handlePlayPause}>
  {isPlaying ? 'Pause' : 'Play'}
</button>
```

---

##### `handleSpeedChange(speed: number): void`
**Description:** Adjusts speech playback rate

**Parameters:**
- `speed`: Playback speed (0.5 to 2.0)

**Usage:**
```typescript
<select onChange={(e) => handleSpeedChange(parseFloat(e.target.value))}>
  <option value="0.5">0.5x</option>
  <option value="1.0">1.0x</option>
  <option value="1.5">1.5x</option>
  <option value="2.0">2.0x</option>
</select>
```

---

### **📅 Reading Plan Functions**

##### `calculateDailyGoal(totalPages: number, totalDays: number): number`
**Description:** Calculates daily reading target

**Parameters:**
- `totalPages`: Total pages in book
- `totalDays`: Days to complete book

**Returns:** `Pages per day`

**Usage:**
```typescript
const dailyPages = calculateDailyGoal(300, 30);
console.log(dailyPages); // 10 pages per day
```

---

##### `updateSchedule(newDays: number): void`
**Description:** Updates reading plan timeline

**Parameters:**
- `newDays`: New total days to complete book

**Side Effects:**
- Updates progress.totalDays
- Recalculates daily goals
- Saves to localStorage

**Usage:**
```typescript
<button onClick={() => updateSchedule(45)}>
  Extend to 45 Days
</button>
```

---

### **🔐 Authentication Functions**

##### `checkAuth(): boolean`
**Description:** Checks if user is authenticated

**Returns:** `true if authenticated, false otherwise`

**Usage:**
```typescript
if (!checkAuth()) {
  return <Onboarding />;
}
```

---

##### `completeOnboarding(userData: any): void`
**Description:** Completes onboarding and saves user data

**Parameters:**
- `userData`: User preferences and settings

**Usage:**
```typescript
completeOnboarding({
  name: "John",
  readingGoal: "30 minutes per day",
  favoriteGenres: ["Fiction", "Science"]
});
```

---

## 🌐 **Supabase API Functions**

### **Database Operations**

#### `insertBook(book: Book): Promise<Book>`
**Description:** Inserts book into Supabase database

**Usage:**
```typescript
const { data, error } = await supabase
  .from('books')
  .insert([book])
  .select();
```

---

#### `getBooks(userId: string): Promise<Book[]>`
**Description:** Fetches all books for a user

**Usage:**
```typescript
const { data: books } = await supabase
  .from('books')
  .select('*')
  .eq('user_id', userId);
```

---

#### `updateProgress(progressId: string, updates: any): Promise<Progress>`
**Description:** Updates reading progress in database

**Usage:**
```typescript
const { data } = await supabase
  .from('reading_progress')
  .update(updates)
  .eq('id', progressId)
  .select();
```

---

## 📊 **Utility Functions**

### `formatDate(dateString: string): string`
**Description:** Formats ISO date string to readable format

**Usage:**
```typescript
const formatted = formatDate('2026-03-15');
console.log(formatted); // "March 15, 2026"
```

---

### `calculatePercentage(current: number, total: number): number`
**Description:** Calculates percentage completion

**Usage:**
```typescript
const percent = calculatePercentage(15, 30);
console.log(percent); // 50
```

---

### `validateBookContent(content: string): boolean`
**Description:** Validates book content before upload

**Checks:**
- Content not empty
- Minimum length requirement
- Valid text format

**Usage:**
```typescript
if (validateBookContent(textContent)) {
  handleUpload();
}
```

---

## 🎯 **TypeScript Interfaces**

### **Core Interfaces**

```typescript
interface Book {
  title: string;
  author: string;
  totalPages: number;
  content: string;
  uploadDate: string;
}

interface Progress {
  currentDay: number;
  totalDays: number;
  completedDays: string[];
  xp: number;
  level: number;
}

interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: any;
  unlocked: boolean;
  progress?: number;
  target?: number;
}

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}
```

---

## 🔧 **Error Handling**

### **Common Errors & Solutions**

#### `Error: "No book found"`
**Cause:** No book uploaded yet
**Solution:** Redirect to upload page

```typescript
if (!book) {
  return <UploadPrompt />;
}
```

---

#### `Error: "Storage quota exceeded"`
**Cause:** localStorage full
**Solution:** Clear old data or use Supabase

```typescript
try {
  saveBook(largeBook);
} catch (error) {
  if (error.name === 'QuotaExceededError') {
    alert('Storage full. Please delete some books.');
  }
}
```

---

#### `Error: "Invalid progress data"`
**Cause:** Corrupted localStorage data
**Solution:** Reset progress with default values

```typescript
try {
  const progress = getProgress();
  if (!progress || !progress.totalDays) {
    throw new Error('Invalid progress');
  }
} catch {
  initializeProgress(30); // Reset to default
}
```

---

## 📚 **Usage Examples**

### **Complete Reading Flow**

```typescript
// 1. Upload new book
const book = {
  title: "1984",
  author: "George Orwell",
  totalPages: 328,
  content: bookText,
  uploadDate: new Date().toISOString()
};
saveBook(book);

// 2. Initialize progress
const progress = initializeProgress(30);

// 3. Complete daily reading
handleMarkComplete(); // Awards 50 XP

// 4. Check achievements
const achievements = checkAchievements(progress);

// 5. Chat about book
const response = await generateAIResponse(
  "What are the main themes?",
  book.content
);

// 6. Listen to audio
handleTextToSpeech(book.content);
```

---

**Last Updated:** March 15, 2026
**API Version:** 0.1.0
**Status:** Active Development