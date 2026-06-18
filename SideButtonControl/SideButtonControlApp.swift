//
//  SideButtonControlApp.swift
//  SideButtonControl
//
//  Created by Hamza Tüfekçi on 18.06.2026.
//

import SwiftUI

@main
struct SideButtonControlApp: App {
    @NSApplicationDelegateAdaptor(SideButtonControlAppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            AppSettingsView()
        }
    }
}

private struct AppSettingsView: View {
    var body: some View {
        Form {
            Text("SideButtonControl arka planda sessiz çalışır.")
            Text("Tanılama için menü çubuğu ikonunu kullan. İkonu gizlersen Cmd-Space ile uygulamayı tekrar açarak geri getirebilirsin.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 420)
    }
}
