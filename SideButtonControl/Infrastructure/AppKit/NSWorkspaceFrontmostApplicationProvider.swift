import AppKit

nonisolated struct NSWorkspaceFrontmostApplicationProvider: FrontmostApplicationProviding {
    func frontmostApplication() -> FrontmostApplication {
        FrontmostApplication(
            bundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        )
    }
}
