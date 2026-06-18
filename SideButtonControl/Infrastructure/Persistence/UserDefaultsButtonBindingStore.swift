import Foundation

/// Stores button assignments as JSON in `UserDefaults`.
final class UserDefaultsButtonBindingStore: ButtonBindingStoring {
    private let defaults: UserDefaults
    private let key = "SideButtonControl.buttonBindings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ButtonBindingSet {
        guard
            let data = defaults.data(forKey: key),
            let bindings = try? JSONDecoder().decode(ButtonBindingSet.self, from: data)
        else {
            return .standard
        }
        return bindings
    }

    func save(_ bindings: ButtonBindingSet) {
        guard let data = try? JSONEncoder().encode(bindings) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}
