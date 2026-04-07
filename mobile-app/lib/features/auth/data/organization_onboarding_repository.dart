import '../../../core/services/backend_api_client.dart';
import '../domain/models/organization_option.dart';

class JoinOrganizationSignUpInput {
  const JoinOrganizationSignUpInput({
    required this.organizationId,
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });

  final String organizationId;
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}

class CreateOrganizationSignUpInput {
  const CreateOrganizationSignUpInput({
    required this.organizationName,
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });

  final String organizationName;
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationName': organizationName,
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}

class OrganizationOnboardingRepository {
  const OrganizationOnboardingRepository({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<List<OrganizationOption>> listOrganizations() async {
    final Map<String, dynamic> response = await _apiClient.getPublicJson(
      '/auth/organizations',
    );
    final dynamic data = response['data'];

    if (data is! List) {
      return <OrganizationOption>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(OrganizationOption.fromJson)
        .toList(growable: false);
  }

  Future<void> signUpForOrganization(JoinOrganizationSignUpInput input) async {
    await _apiClient.postPublicJson('/auth/signup/join', body: input.toJson());
  }

  Future<void> signUpAsOrganization(CreateOrganizationSignUpInput input) async {
    await _apiClient.postPublicJson(
      '/auth/signup/organization',
      body: input.toJson(),
    );
  }
}
