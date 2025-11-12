import Foundation

// FIX 2, 3, 4: This new file defines the missing Notification.Name,
// which resolves all three publisher-related errors in HomeViewModel.

extension Notification.Name {
    /// Notification posted when a new HealthKit activity (sleep, mindfulness, exercise) is logged.
    /// The `object` of the notification is expected to be a `LoggedActivity`.
    static let didLogHealthKitActivity = Notification.Name("didLogHealthKitActivity")
}
