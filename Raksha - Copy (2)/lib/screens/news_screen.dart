import 'package:flutter/material.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articles = NewsService.articles;
    final blogs = NewsService.blogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Women Safety & Laws"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Articles", icon: Icon(Icons.article)),
            Tab(text: "Blogs", icon: Icon(Icons.book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Articles Tab
          articles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No articles available",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: articles.length,
                  itemBuilder: (c, i) {
                    final article = articles[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.article, color: Colors.white),
                        ),
                        title: Text(
                          article["title"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(article["desc"]!),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to article detail screen
                        },
                      ),
                    );
                  },
                ),
          // Blogs Tab
          blogs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No blogs available",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: blogs.length,
                  itemBuilder: (c, i) {
                    final blog = blogs[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(
                          blog["title"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Text(blog["desc"]!),
                            ),
                            Row(
                              children: [
                                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  blog["author"] ?? "Anonymous",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  blog["date"] ?? "",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigate to blog detail screen
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
