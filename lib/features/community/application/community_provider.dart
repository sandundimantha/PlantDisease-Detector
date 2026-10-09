import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/features/community/data/community_models.dart';

final communityFeedProvider = AsyncNotifierProvider<CommunityFeedNotifier, List<CommunityPost>>(() {
  return CommunityFeedNotifier();
});

class CommunityFeedNotifier extends AsyncNotifier<List<CommunityPost>> {
  final _client = Supabase.instance.client;

  @override
  Future<List<CommunityPost>> build() async {
    return _fetchPosts();
  }

  Future<List<CommunityPost>> _fetchPosts() async {
    final response = await _client
        .from('community_posts')
        .select('''
          *,
          profiles (id, full_name, avatar_url, district),
          community_likes (user_id)
        ''')
        .order('created_at', ascending: false);

    final currentUserId = _client.auth.currentUser?.id;

    return (response as List).map((row) {
      final profileData = row['profiles'] as Map<String, dynamic>?;
      CommunityUser? author;
      if (profileData != null) {
        author = CommunityUser(
          id: profileData['id'] ?? '',
          fullName: profileData['full_name'] ?? 'Unknown Farmer',
          imagePath: profileData['avatar_url'],
          location: profileData['district'] ?? 'Unknown Location',
        );
      }

      final likes = row['community_likes'] as List?;
      final isLikedByMe = currentUserId != null && 
          likes != null && 
          likes.any((like) => like['user_id'] == currentUserId);

      return CommunityPost.fromJson(
        row,
        author: author,
        isLikedByMe: isLikedByMe,
      );
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPosts());
  }

  Future<void> createPost(String content, {String? title, String? imageUrl, String category = 'General'}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('community_posts').insert({
      'user_id': user.id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'category': category,
    });

    ref.invalidateSelf();
  }

  Future<void> editPost(String postId, String content, {String? title, String? imageUrl, String category = 'General'}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final rows = await _client.from('community_posts').update({
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'category': category,
    }).eq('id', postId).eq('user_id', user.id).select('id');

    ref.invalidateSelf();
    // RLS returns no rows instead of an error when the edit is not allowed.
    if ((rows as List).isEmpty) throw Exception('Post was not updated');
  }

  Future<void> deletePost(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final currentPosts = state.value;
    if (currentPosts != null) {
      state = AsyncValue.data(currentPosts.where((p) => p.id != postId).toList());
    }

    try {
      final rows = await _client.from('community_posts').delete().eq('id', postId).eq('user_id', user.id).select('id');
      if ((rows as List).isEmpty) throw Exception('Post was not deleted');
    } catch (e) {
      ref.invalidateSelf(); // bring the post back
      rethrow;
    }
  }

  Future<void> toggleLike(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final currentPosts = state.value;
    if (currentPosts == null) return;

    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentPosts[postIndex];
    final isLiked = post.isLikedByMe;

    // Optimistic update
    final updatedPost = post.copyWith(
      isLikedByMe: !isLiked,
      likesCount: post.likesCount + (isLiked ? -1 : 1),
    );
    
    final newPosts = List<CommunityPost>.from(currentPosts);
    newPosts[postIndex] = updatedPost;
    state = AsyncValue.data(newPosts);

    try {
      if (isLiked) {
        await _client
            .from('community_likes')
            .delete()
            .match({'post_id': postId, 'user_id': user.id});
        await _client.rpc('decrement_like', params: {'pid': postId});
      } else {
        await _client
            .from('community_likes')
            .insert({'post_id': postId, 'user_id': user.id});
        await _client.rpc('increment_like', params: {'pid': postId});
      }
    } catch (e) {
      // Revert optimistic update on error
      ref.invalidateSelf();
    }
  }
}

// Comments Provider (Family scoped by postId)
final postCommentsProvider = AsyncNotifierProviderFamily<PostCommentsNotifier, List<CommunityComment>, String>(() {
  return PostCommentsNotifier();
});

class PostCommentsNotifier extends FamilyAsyncNotifier<List<CommunityComment>, String> {
  final _client = Supabase.instance.client;

  @override
  Future<List<CommunityComment>> build(String arg) async {
    return _fetchComments(arg);
  }

  Future<List<CommunityComment>> _fetchComments(String postId) async {
    final response = await _client
        .from('community_comments')
        .select('''
          *,
          profiles (id, full_name, avatar_url, district)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List).map((row) {
      final profileData = row['profiles'] as Map<String, dynamic>?;
      CommunityUser? author;
      if (profileData != null) {
        author = CommunityUser(
          id: profileData['id'] ?? '',
          fullName: profileData['full_name'] ?? 'Unknown',
          imagePath: profileData['avatar_url'],
          location: profileData['district'] ?? '',
        );
      }

      return CommunityComment.fromJson(row, author: author);
    }).toList();
  }

  Future<void> addComment(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('community_comments').insert({
      'post_id': arg,
      'user_id': user.id,
      'content': content,
    });
    
    // Also increment comment count
    await _client.rpc('increment_comment', params: {'pid': arg});

    ref.invalidateSelf();
    // Invalidate main feed so comment count updates
    ref.invalidate(communityFeedProvider);
  }
}
