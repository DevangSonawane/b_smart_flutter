class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isOnline;
  final int followers;
  final int following;
  final int posts;
  final int coins;
  final String? bio;
  final String? address;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.isOnline = false,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.coins = 0,
    this.bio,
    this.address,
  });
}
