/// Persists the user's button assignments across launches.
protocol ButtonBindingStoring: AnyObject {
    func load() -> ButtonBindingSet
    func save(_ bindings: ButtonBindingSet)
}
