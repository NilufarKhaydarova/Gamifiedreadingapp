import '../models/catalog_book.dart';

class CatalogService {
  static const List<CatalogBook> _books = [
    // ── Philosophy ────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'Meditations',
      author: 'Marcus Aurelius',
      description:
          'A series of personal writings by the Roman Emperor Marcus Aurelius, recording his private notes and thoughts on Stoic philosophy. Written as a source of self-guidance and self-improvement, Meditations remains one of the greatest works of philosophy—a roadmap for living a life of virtue, resilience, and inner peace.',
      year: 180,
      genre: 'Philosophy',
      emoji: '🏛️',
      difficulty: 'Accessible',
      pages: 254,
    ),
    CatalogBook(
      title: 'The Republic',
      author: 'Plato',
      description:
          'Plato\'s masterwork explores justice, the ideal state, and the nature of the philosopher-king through a series of Socratic dialogues. It introduces the famous Allegory of the Cave and examines how society should be organized for human flourishing, making it a cornerstone of Western political and ethical thought.',
      year: -380,
      genre: 'Philosophy',
      emoji: '⚖️',
      difficulty: 'Challenging',
      pages: 416,
    ),
    CatalogBook(
      title: 'Nicomachean Ethics',
      author: 'Aristotle',
      description:
          'Aristotle\'s foundational work on ethics examines what constitutes the good life for human beings. Central to the work is the concept of eudaimonia (happiness or flourishing) and the idea that virtue is a habit cultivated through practice. It remains one of the most influential texts in moral philosophy.',
      year: -350,
      genre: 'Philosophy',
      emoji: '🌿',
      difficulty: 'Challenging',
      pages: 368,
    ),
    CatalogBook(
      title: 'Thus Spoke Zarathustra',
      author: 'Friedrich Nietzsche',
      description:
          'A philosophical novel in which the prophet Zarathustra descends from his mountain retreat to share his revolutionary ideas with humanity—including the Overman, eternal recurrence, and the death of God. Written in lyrical, quasi-biblical prose, it is Nietzsche\'s most celebrated and provocative work.',
      year: 1883,
      genre: 'Philosophy',
      emoji: '⚡',
      difficulty: 'Challenging',
      pages: 352,
    ),
    CatalogBook(
      title: 'Beyond Good and Evil',
      author: 'Friedrich Nietzsche',
      description:
          'Nietzsche attacks the foundations of past philosophical thinking, including the concepts of free will, objective truth, and conventional morality. He calls for a transvaluation of values and the emergence of a new kind of philosopher willing to create new values for a post-Christian world.',
      year: 1886,
      genre: 'Philosophy',
      emoji: '🦅',
      difficulty: 'Moderate',
      pages: 240,
    ),

    // ── Psychology ────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      description:
          'Nobel laureate Daniel Kahneman distills decades of research into a groundbreaking tour of the mind. He explains two systems that drive the way we think: System 1 (fast, intuitive) and System 2 (slow, deliberate). The book reveals the cognitive biases that affect our decisions in every area of life.',
      year: 2011,
      genre: 'Psychology',
      emoji: '🧠',
      difficulty: 'Moderate',
      pages: 499,
    ),
    CatalogBook(
      title: "Man's Search for Meaning",
      author: 'Viktor E. Frankl',
      description:
          'Psychiatrist Viktor Frankl\'s memoir of surviving the Nazi concentration camps reveals his psychotherapeutic method—logotherapy—which is founded on the belief that the primary human drive is not pleasure but the pursuit of meaning. A profound testament to the indestructibility of the human spirit.',
      year: 1946,
      genre: 'Psychology',
      emoji: '🕯️',
      difficulty: 'Accessible',
      pages: 184,
    ),
    CatalogBook(
      title: 'Flow',
      author: 'Mihaly Csikszentmihalyi',
      description:
          'Psychologist Mihaly Csikszentmihalyi introduces the concept of "flow"—the state of complete immersion and enjoyment in a challenging activity. Drawing on decades of research, he shows how achieving flow in work, relationships, and leisure leads to a richer, more fulfilling life.',
      year: 1990,
      genre: 'Psychology',
      emoji: '🌊',
      difficulty: 'Accessible',
      pages: 303,
    ),
    CatalogBook(
      title: 'Influence',
      author: 'Robert B. Cialdini',
      description:
          'Dr. Cialdini identifies the six universal principles of influence—reciprocity, commitment, social proof, authority, liking, and scarcity—and explains how they shape our decisions. Essential reading for anyone who wants to understand persuasion, whether to use it ethically or defend against it.',
      year: 1984,
      genre: 'Psychology',
      emoji: '🎯',
      difficulty: 'Accessible',
      pages: 336,
    ),
    CatalogBook(
      title: 'The Power of Habit',
      author: 'Charles Duhigg',
      description:
          'Charles Duhigg explores the science behind habit formation and change, revealing why habits exist and how they can be transformed. Through compelling stories from business, sports, and neuroscience, he demonstrates that the key to success lies in understanding how habits work at the neurological level.',
      year: 2012,
      genre: 'Psychology',
      emoji: '🔄',
      difficulty: 'Accessible',
      pages: 371,
    ),

    // ── Fiction ────────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'Crime and Punishment',
      author: 'Fyodor Dostoevsky',
      description:
          'A young, impoverished student in St. Petersburg commits a murder he believes is philosophically justified—and then grapples with guilt, paranoia, and spiritual redemption. Dostoevsky\'s psychological masterpiece plumbs the depths of the human conscience and the nature of transgression.',
      year: 1866,
      genre: 'Fiction',
      emoji: '🪓',
      difficulty: 'Moderate',
      pages: 551,
    ),
    CatalogBook(
      title: 'Anna Karenina',
      author: 'Leo Tolstoy',
      description:
          'Widely considered one of the greatest novels ever written, Anna Karenina follows the tragic love affair of the beautiful aristocrat Anna and the dashing Count Vronsky against the backdrop of Russian high society. Tolstoy weaves together themes of love, betrayal, faith, and social convention.',
      year: 1877,
      genre: 'Fiction',
      emoji: '🌹',
      difficulty: 'Moderate',
      pages: 864,
    ),
    CatalogBook(
      title: '1984',
      author: 'George Orwell',
      description:
          'In a totalitarian future state ruled by Big Brother, Winston Smith secretly rebels against the oppressive Party. Orwell\'s chilling dystopia has given us Newspeak, doublethink, and Room 101—concepts that remain as relevant as ever in an age of surveillance and political manipulation.',
      year: 1949,
      genre: 'Fiction',
      emoji: '👁️',
      difficulty: 'Accessible',
      pages: 328,
    ),
    CatalogBook(
      title: 'Brave New World',
      author: 'Aldous Huxley',
      description:
          'In a future society engineered for stability and pleasure, where humans are produced in hatcheries and conditioned for contentment, Bernard Marx dares to question whether happiness without freedom is worth having. Huxley\'s prophetic novel asks whether comfort is worth the price of humanity.',
      year: 1932,
      genre: 'Fiction',
      emoji: '🧪',
      difficulty: 'Accessible',
      pages: 311,
    ),
    CatalogBook(
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      description:
          'Narrated by young Scout Finch, this Pulitzer Prize-winning novel follows her father Atticus, a lawyer who defends a Black man falsely accused of a crime in Depression-era Alabama. A profound exploration of racial injustice, moral growth, and the loss of innocence.',
      year: 1960,
      genre: 'Fiction',
      emoji: '🐦',
      difficulty: 'Accessible',
      pages: 281,
    ),
    CatalogBook(
      title: 'The Brothers Karamazov',
      author: 'Fyodor Dostoevsky',
      description:
          'Dostoevsky\'s final and greatest novel centers on the murder of a depraved landowner and the spiritual crisis of his sons. A philosophical novel at its core, it wrestles with faith, doubt, free will, and morality through some of literature\'s most memorable characters.',
      year: 1880,
      genre: 'Fiction',
      emoji: '⛪',
      difficulty: 'Challenging',
      pages: 796,
    ),
    CatalogBook(
      title: 'One Hundred Years of Solitude',
      author: 'Gabriel García Márquez',
      description:
          'The multigenerational saga of the Buendía family in the fictional town of Macondo, told in the style of magical realism that García Márquez made famous. Winner of the Nobel Prize in Literature, it is a dazzling blend of the real and the fantastical, exploring love, power, and the cycles of history.',
      year: 1967,
      genre: 'Fiction',
      emoji: '🦋',
      difficulty: 'Moderate',
      pages: 448,
    ),
    CatalogBook(
      title: 'Don Quixote',
      author: 'Miguel de Cervantes',
      description:
          'Often called the first modern novel, Don Quixote follows the misadventures of an aging knight-errant and his loyal squire Sancho Panza as they tilt at windmills and pursue chivalric ideals in a world that has moved on. A rich meditation on reality, illusion, and the power of imagination.',
      year: 1605,
      genre: 'Fiction',
      emoji: '⚔️',
      difficulty: 'Moderate',
      pages: 1023,
    ),
    CatalogBook(
      title: 'Moby Dick',
      author: 'Herman Melville',
      description:
          'Captain Ahab\'s monomaniacal quest for the white whale that took his leg drives the crew of the Pequod toward their doom. Part adventure story, part philosophical meditation, Melville\'s novel is a vast, symbolic exploration of obsession, fate, and humanity\'s struggle against nature.',
      year: 1851,
      genre: 'Fiction',
      emoji: '🐋',
      difficulty: 'Challenging',
      pages: 720,
    ),
    CatalogBook(
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description:
          'Narrated by the observer Nick Carraway, this Jazz Age novel follows the enigmatic millionaire Jay Gatsby and his obsessive pursuit of the beautiful Daisy Buchanan. A scathing critique of the American Dream, it captures the glittering excess and hollow ambitions of the Roaring Twenties.',
      year: 1925,
      genre: 'Fiction',
      emoji: '🥂',
      difficulty: 'Accessible',
      pages: 180,
    ),

    // ── Science ────────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'A Brief History of Time',
      author: 'Stephen Hawking',
      description:
          'Stephen Hawking\'s landmark popular science book explores the universe\'s origins, the nature of time, black holes, and the search for a unified theory of physics. Written for general audiences without mathematics, it opened the wonders of theoretical physics to millions of readers worldwide.',
      year: 1988,
      genre: 'Science',
      emoji: '🌌',
      difficulty: 'Moderate',
      pages: 212,
    ),
    CatalogBook(
      title: 'The Selfish Gene',
      author: 'Richard Dawkins',
      description:
          'Dawkins presents a gene-centered view of evolution, arguing that organisms are "survival machines" built by genes to propagate themselves. He introduces the concept of the "meme"—a cultural unit of transmission—and makes a compelling case for why understanding genetics is essential to understanding life.',
      year: 1976,
      genre: 'Science',
      emoji: '🧬',
      difficulty: 'Moderate',
      pages: 360,
    ),
    CatalogBook(
      title: 'Cosmos',
      author: 'Carl Sagan',
      description:
          'Carl Sagan\'s landmark companion to his television series takes readers on a journey through space and time, exploring the origins of life, the nature of intelligence, and humanity\'s place in the cosmos. Written with poetic wonder and scientific rigor, it remains an inspiring call to cosmic perspective.',
      year: 1980,
      genre: 'Science',
      emoji: '🪐',
      difficulty: 'Accessible',
      pages: 365,
    ),
    CatalogBook(
      title: 'The Structure of Scientific Revolutions',
      author: 'Thomas S. Kuhn',
      description:
          'Kuhn\'s revolutionary work introduced the concept of the "paradigm shift" to describe how scientific progress really happens—not gradually, but through sudden, dramatic changes in worldview. One of the most cited academic books ever written, it transformed how we understand the history of science.',
      year: 1962,
      genre: 'Science',
      emoji: '🔭',
      difficulty: 'Challenging',
      pages: 264,
    ),
    CatalogBook(
      title: 'Sapiens',
      author: 'Yuval Noah Harari',
      description:
          'A sweeping history of humankind from the Stone Age through the twenty-first century, Sapiens asks why Homo sapiens came to dominate the planet. Harari argues that our ability to believe in shared fictions—money, nations, religions—is what enabled large-scale cooperation and civilization.',
      year: 2011,
      genre: 'Science',
      emoji: '🦴',
      difficulty: 'Accessible',
      pages: 443,
    ),

    // ── History ────────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'Guns, Germs, and Steel',
      author: 'Jared Diamond',
      description:
          'Winner of the Pulitzer Prize, this book asks why certain civilizations came to dominate others. Diamond argues that geography, not racial or intellectual differences, determined which societies developed the guns, germs, and steel that allowed them to conquer the world.',
      year: 1997,
      genre: 'History',
      emoji: '🌍',
      difficulty: 'Moderate',
      pages: 480,
    ),
    CatalogBook(
      title: 'The Art of War',
      author: 'Sun Tzu',
      description:
          'Written by the ancient Chinese military strategist Sun Tzu, this short but profound treatise on military strategy has been applied to business, law, sports, and politics for centuries. Its thirteen chapters offer timeless wisdom on conflict, leadership, adaptability, and the importance of intelligence.',
      year: -500,
      genre: 'History',
      emoji: '🗡️',
      difficulty: 'Accessible',
      pages: 68,
    ),
    CatalogBook(
      title: 'The Prince',
      author: 'Niccolò Machiavelli',
      description:
          'Written as a political manual for rulers, Machiavelli\'s notorious treatise advises that political leaders must be willing to use any means necessary to maintain power. Controversial for its unflinching pragmatism, The Prince gave us the adjective "Machiavellian" and remains essential reading in political science.',
      year: 1532,
      genre: 'History',
      emoji: '👑',
      difficulty: 'Accessible',
      pages: 140,
    ),

    // ── Economics ─────────────────────────────────────────────────────────────
    CatalogBook(
      title: 'The Wealth of Nations',
      author: 'Adam Smith',
      description:
          'The foundational text of modern economics, Smith\'s magnum opus introduced concepts still central to economic thought: the division of labor, the invisible hand, and free markets. Published in 1776, it made the case for capitalism and limited government intervention in the economy.',
      year: 1776,
      genre: 'Economics',
      emoji: '💰',
      difficulty: 'Challenging',
      pages: 1097,
    ),
    CatalogBook(
      title: 'Capital',
      author: 'Karl Marx',
      description:
          'Marx\'s monumental critique of capitalism analyzes the nature of commodities, labor, value, and capital accumulation. He argues that the capitalist system is inherently exploitative of workers and contains the seeds of its own destruction. One of the most influential—and controversial—books ever written.',
      year: 1867,
      genre: 'Economics',
      emoji: '⚙️',
      difficulty: 'Challenging',
      pages: 1152,
    ),
  ];

  static List<String> get genres {
    final seen = <String>{};
    final result = <String>[];
    for (final book in _books) {
      if (seen.add(book.genre)) {
        result.add(book.genre);
      }
    }
    return result;
  }

  static List<CatalogBook> get allBooks => _books;

  static List<CatalogBook> byGenre(String genre) {
    return _books.where((b) => b.genre == genre).toList();
  }

  static List<CatalogBook> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _books;
    return _books.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q) ||
          b.genre.toLowerCase().contains(q);
    }).toList();
  }
}
