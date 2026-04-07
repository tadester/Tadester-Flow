import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_api_client.dart';
import '../../data/organization_onboarding_repository.dart';
import '../../domain/models/organization_option.dart';

final Provider<OrganizationOnboardingRepository>
organizationOnboardingRepositoryProvider =
    Provider<OrganizationOnboardingRepository>((Ref ref) {
      return OrganizationOnboardingRepository(
        apiClient: ref.read(backendApiClientProvider),
      );
    });

final FutureProvider<List<OrganizationOption>> availableOrganizationsProvider =
    FutureProvider<List<OrganizationOption>>((Ref ref) {
      return ref
          .read(organizationOnboardingRepositoryProvider)
          .listOrganizations();
    });
