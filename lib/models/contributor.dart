class Contributor {
  final String login;
  final int contributions;
  final String avatarUrl;
  final String htmlUrl;

  Contributor({
    required this.login,
    required this.contributions,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  factory Contributor.fromJson(Map<String, dynamic> json) {
    return Contributor(
      login: json['login'],
      contributions: json['contributions'],
      avatarUrl: json['avatar_url'],
      htmlUrl: json['html_url'],
    );
  }
}