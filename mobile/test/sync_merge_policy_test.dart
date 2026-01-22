// Unit tests for sync merge rules to protect offline-first behavior.
// This exists to validate conflict detection and merge decisions.
// It fits in the app by guarding the core sync policy against regressions.
import 'package:test/test.dart';

import 'package:mobile/domain/sync/sync_merge_policy.dart';
import 'package:mobile/domain/sync/sync_status.dart';

void main() {
  const policy = SyncMergePolicy();

  test('pending local change conflicts with newer server update', () {
    final decision = policy.decide(
      localStatus: SyncStatus.pending,
      localServerUpdatedAt: DateTime.utc(2025, 1, 10),
      remoteServerUpdatedAt: DateTime.utc(2025, 1, 11),
      localDeleted: false,
      remoteDeleted: false,
    );

    expect(decision, MergeDecision.conflict);
  });

  test('pending local change keeps local when server is older', () {
    final decision = policy.decide(
      localStatus: SyncStatus.pending,
      localServerUpdatedAt: DateTime.utc(2025, 1, 11),
      remoteServerUpdatedAt: DateTime.utc(2025, 1, 10),
      localDeleted: false,
      remoteDeleted: false,
    );

    expect(decision, MergeDecision.keepLocal);
  });

  test('synced local applies newer server update', () {
    final decision = policy.decide(
      localStatus: SyncStatus.synced,
      localServerUpdatedAt: DateTime.utc(2025, 1, 10),
      remoteServerUpdatedAt: DateTime.utc(2025, 1, 12),
      localDeleted: false,
      remoteDeleted: false,
    );

    expect(decision, MergeDecision.applyRemote);
  });

  test('synced local keeps local when server is same or older', () {
    final decision = policy.decide(
      localStatus: SyncStatus.synced,
      localServerUpdatedAt: DateTime.utc(2025, 1, 12),
      remoteServerUpdatedAt: DateTime.utc(2025, 1, 12),
      localDeleted: false,
      remoteDeleted: false,
    );

    expect(decision, MergeDecision.keepLocal);
  });

  test('conflict status never auto-merges', () {
    final decision = policy.decide(
      localStatus: SyncStatus.conflict,
      localServerUpdatedAt: DateTime.utc(2025, 1, 10),
      remoteServerUpdatedAt: DateTime.utc(2025, 1, 12),
      localDeleted: false,
      remoteDeleted: false,
    );

    expect(decision, MergeDecision.keepLocal);
  });
}
