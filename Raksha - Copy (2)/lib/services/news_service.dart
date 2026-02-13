class NewsService {
  static List<Map<String, String>> articles = [
    {
      "title": "Know Your Rights",
      "desc": "IPC sections for women's safety explained simply.",
      "type": "article",
    },
    {
      "title": "Self Defense Tips",
      "desc": "How to protect yourself in public spaces.",
      "type": "article",
    },
  ];

  static List<Map<String, String>> blogs = [
    {
      "title": "10 Essential Safety Tips for Women Traveling Alone",
      "desc": "Learn important safety measures and precautions when traveling solo. Stay safe and confident on your journeys.",
      "type": "blog",
      "author": "Safety Expert",
      "date": "2024-01-15",
    },
    {
      "title": "Understanding Your Legal Rights: A Complete Guide",
      "desc": "Comprehensive guide to understanding your legal rights in various situations. Know what to do when your rights are violated.",
      "type": "blog",
      "author": "Legal Advisor",
      "date": "2024-01-10",
    },
    {
      "title": "Building Confidence: Self-Defense Techniques That Work",
      "desc": "Practical self-defense techniques you can learn and practice. Build confidence and stay prepared for any situation.",
      "type": "blog",
      "author": "Self-Defense Instructor",
      "date": "2024-01-05",
    },
    {
      "title": "Creating a Safety Network: Why Guardians Matter",
      "desc": "Learn how to build a reliable safety network and why having trusted guardians is crucial for your safety.",
      "type": "blog",
      "author": "Safety Advocate",
      "date": "2024-01-01",
    },
    {
      "title": "Technology and Safety: How Apps Can Keep You Safe",
      "desc": "Explore how modern technology and safety apps can help protect you in emergency situations.",
      "type": "blog",
      "author": "Tech Safety Expert",
      "date": "2023-12-28",
    },
  ];

  static List<Map<String, String>> getAllContent() {
    return [...articles, ...blogs];
  }
}
