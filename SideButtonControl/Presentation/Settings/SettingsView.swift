import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: DetectionViewModel
    var onOpenDiagnostics: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            hero
            Divider()
            footer
        }
        .frame(width: 520)
        .background(.background)
        .onAppear {
            viewModel.refreshPermissions()
            appeared = true
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            VStack(spacing: 3) {
                Text("SideButtonControl")
                    .font(.title2.weight(.semibold))
                Text("Yan fare tuşlarına işlev ata")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            DeathAdderStyleMouseHero(
                bindings: viewModel.bindings.bindings,
                commandFor: { viewModel.bindings.command(for: $0) },
                onSelect: { command, button in
                    viewModel.updateCommand(command, for: button)
                }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.easeOut(duration: 0.35), value: appeared)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isRunning ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(viewModel.isRunning ? "Çalışıyor" : "Durduruldu")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onOpenDiagnostics) {
                HStack(spacing: 4) {
                    Text("Tanılama")
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                }
            }
            .buttonStyle(.link)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView(viewModel: AppContainer().detectionViewModel, onOpenDiagnostics: {})
}
