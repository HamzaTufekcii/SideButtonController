@MainActor
final class DisplayDrivenDetectionController {
    private let viewModel: DetectionViewModel
    private let displayMonitor: any ExternalDisplayMonitoring
    private let statusBarController: StatusBarController

    init(
        viewModel: DetectionViewModel,
        displayMonitor: any ExternalDisplayMonitoring,
        statusBarController: StatusBarController
    ) {
        self.viewModel = viewModel
        self.displayMonitor = displayMonitor
        self.statusBarController = statusBarController
    }

    func start() {
        displayMonitor.start { [weak self] snapshot in
            self?.apply(snapshot)
        }
    }

    func stop() {
        displayMonitor.stop()
        statusBarController.closeInteractiveWindows()
        viewModel.suspendDetection()
        statusBarController.refreshStatusItem()
    }

    private func apply(_ snapshot: ExternalDisplaySnapshot) {
        viewModel.setExternalDisplayAvailable(snapshot.hasExternalDisplay)

        if snapshot.hasExternalDisplay {
            statusBarController.installMenuBarIcon()
            viewModel.startDetectionIfAuthorized()
            statusBarController.refreshStatusItem()
        } else {
            statusBarController.closeInteractiveWindows()
            viewModel.suspendDetection()
            statusBarController.removeMenuBarIcon()
        }
    }
}
