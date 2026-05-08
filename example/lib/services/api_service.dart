import 'package:dio/dio.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/comment.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio _dio;

  ApiService(this._dio);

  /// Fetch all posts
  Future<List<Post>> getPosts() async {
    try {
      final response = await _dio.get<List<dynamic>>('$baseUrl/posts');

      if (response.statusCode == 200) {
        return (response.data ?? [])
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load posts: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single post by ID
  Future<Post> getPost(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/posts/$id',
      );

      if (response.statusCode == 200) {
        return Post.fromJson(response.data!);
      }
      throw Exception('Failed to load post: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new post
  Future<Post> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/posts',
        data: {'userId': userId, 'title': title, 'body': body},
      );

      if (response.statusCode == 201) {
        return Post.fromJson(response.data!);
      }
      throw Exception('Failed to create post: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all users
  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get<List<dynamic>>('$baseUrl/users');

      if (response.statusCode == 200) {
        return (response.data ?? [])
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single user by ID
  Future<User> getUser(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/users/$id',
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data!);
      }
      throw Exception('Failed to load user: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch comments for a specific post
  Future<List<Comment>> getComments(int postId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$baseUrl/posts/$postId/comments',
      );

      if (response.statusCode == 200) {
        return (response.data ?? [])
            .map((json) => Comment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load comments: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Update a post
  Future<Post> updatePost({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$baseUrl/posts/$id',
        data: {'title': title, 'body': body},
      );

      if (response.statusCode == 200) {
        return Post.fromJson(response.data!);
      }
      throw Exception('Failed to update post: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(int id) async {
    try {
      final response = await _dio.delete('$baseUrl/posts/$id');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
