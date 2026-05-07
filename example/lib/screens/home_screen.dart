import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Dio dio;

  const HomeScreen({
    required this.dio,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _apiService;
  String _status = 'Ready to test API calls';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(widget.dio);
  }

  void _updateStatus(String message) {
    setState(() {
      _status = message;
    });
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _showResults(List<dynamic> items, String itemType) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$itemType Results (${items.length})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in items.asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('${entry.key + 1}. ${entry.value.toString()}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPosts() async {
    _setLoading(true);
    _updateStatus('Fetching posts...');
    try {
      final posts = await _apiService.getPosts();
      _updateStatus('✓ Fetched ${posts.length} posts');
      _showResults(posts, 'Posts');
    } catch (e) {
      _updateStatus('✗ Error fetching posts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchUsers() async {
    _setLoading(true);
    _updateStatus('Fetching users...');
    try {
      final users = await _apiService.getUsers();
      _updateStatus('✓ Fetched ${users.length} users');
      _showResults(users, 'Users');
    } catch (e) {
      _updateStatus('✗ Error fetching users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchSinglePost() async {
    _setLoading(true);
    _updateStatus('Fetching post #1...');
    try {
      final post = await _apiService.getPost(1);
      _updateStatus('✓ Fetched post: ${post.title}');
      _showResults([post], 'Post');
    } catch (e) {
      _updateStatus('✗ Error fetching post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createPost() async {
    _setLoading(true);
    _updateStatus('Creating new post...');
    try {
      final newPost = await _apiService.createPost(
        userId: 1,
        title: 'Test Post from Interceptify Example',
        body: 'This is a test post created at ${DateTime.now()}',
      );
      _updateStatus('✓ Created post with ID: ${newPost.id}');
      _showResults([newPost], 'Created Post');
    } catch (e) {
      _updateStatus('✗ Error creating post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updatePost() async {
    _setLoading(true);
    _updateStatus('Updating post #1...');
    try {
      final updatedPost = await _apiService.updatePost(
        id: 1,
        title: 'Updated Title from Interceptify',
        body: 'Updated body at ${DateTime.now()}',
      );
      _updateStatus('✓ Updated post #1');
      _showResults([updatedPost], 'Updated Post');
    } catch (e) {
      _updateStatus('✗ Error updating post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _deletePost() async {
    _setLoading(true);
    _updateStatus('Deleting post #101...');
    try {
      await _apiService.deletePost(101);
      _updateStatus('✓ Deleted post #101');
    } catch (e) {
      _updateStatus('✗ Error deleting post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchComments() async {
    _setLoading(true);
    _updateStatus('Fetching comments for post #1...');
    try {
      final comments = await _apiService.getComments(1);
      _updateStatus('✓ Fetched ${comments.length} comments');
      _showResults(comments, 'Comments');
    } catch (e) {
      _updateStatus('✗ Error fetching comments: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interceptify Example'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📡 API Testing Console',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap buttons below to make API calls to JSONPlaceholder.\n'
                        'Open Flutter DevTools and go to Interceptify tab to see all requests captured in real-time.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _status.contains('✗')
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // GET Requests Section
              const Text(
                'GET Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchPosts,
                icon: const Icon(Icons.list),
                label: const Text('Fetch All Posts'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchSinglePost,
                icon: const Icon(Icons.article),
                label: const Text('Fetch Single Post (#1)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchUsers,
                icon: const Icon(Icons.people),
                label: const Text('Fetch All Users'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchComments,
                icon: const Icon(Icons.comment),
                label: const Text('Fetch Comments (Post #1)'),
              ),
              const SizedBox(height: 20),
              // POST/PUT/DELETE Requests Section
              const Text(
                'POST/PUT/DELETE Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createPost,
                icon: const Icon(Icons.add),
                label: const Text('Create New Post'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updatePost,
                icon: const Icon(Icons.edit),
                label: const Text('Update Post (#1)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _deletePost,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Post (#101)'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Tip: Each request appears in the Interceptify DevTools tab.\n'
                  'You can inspect headers, request body, response data, and timing information.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
