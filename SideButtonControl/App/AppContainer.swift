@MainActor
final class AppContainer {
    let detectionViewModel: DetectionViewModel
    private let statusBarController: StatusBarController
    private let displayDrivenDetectionController: DisplayDrivenDetectionController

    init() {
        // Apps that ignore the navigation swipe gesture and only respond to their
        // keyboard shortcut. Everything else uses the (beep-free) swipe.
        let keyboardRoutedBundleIdentifiers: Set<String> = ["com.spotify.client"]
        let frontmostApplicationProvider = NSWorkspaceFrontmostApplicationProvider()
        let keyboardDispatcher = CGKeyboardShortcutActionDispatcher(
            frontmostApplicationProvider: frontmostApplicationProvider,
            routingPolicy: CGKeyboardShortcutRoutingPolicy(
                commandBracketBundleIdentifiers: [],
                commandOptionArrowBundleIdentifiers: keyboardRoutedBundleIdentifiers
            )
        )
        let actionDispatcher = CompositeNavigationActionDispatcher(
            frontmostApplicationProvider: frontmostApplicationProvider,
            keyboardRoutedBundleIdentifiers: keyboardRoutedBundleIdentifiers,
            keyboardDispatcher: keyboardDispatcher,
            gestureDispatcher: GestureSwipeActionDispatcher()
        )
        let bindingStore = UserDefaultsButtonBindingStore()
        let monitor = CGEventTapMouseEventMonitor(
            bindings: bindingStore.load(),
            actionDispatcher: actionDispatcher
        )
        let permissionClient = CGEventPermissionClient()
        let useCase = SideButtonDetectionUseCase(
            monitor: monitor,
            permissionChecker: permissionClient,
            settingsOpener: permissionClient,
            bindingStore: bindingStore
        )
        self.detectionViewModel = DetectionViewModel(useCase: useCase)
        self.statusBarController = StatusBarController(viewModel: detectionViewModel)
        self.displayDrivenDetectionController = DisplayDrivenDetectionController(
            viewModel: detectionViewModel,
            displayMonitor: AppKitExternalDisplayMonitor(),
            statusBarController: statusBarController
        )
    }

    func start() {
        statusBarController.installMenuBarIcon()
        displayDrivenDetectionController.start()
    }

    func showSettings() {
        statusBarController.installMenuBarIcon()
        statusBarController.showSettings()
    }

    func showDiagnostics() {
        statusBarController.installMenuBarIcon()
        statusBarController.showDiagnostics()
    }

    func stop() {
        displayDrivenDetectionController.stop()
    }
}
