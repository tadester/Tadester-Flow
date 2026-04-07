class OrganizationOption {
  const OrganizationOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory OrganizationOption.fromJson(Map<String, dynamic> json) {
    return OrganizationOption(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed organization',
      slug: json['slug'] as String? ?? '',
    );
  }
}
