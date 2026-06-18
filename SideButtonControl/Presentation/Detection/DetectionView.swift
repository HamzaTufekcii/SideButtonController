import SwiftUI

struct DetectionView: View {
    @Bindable var viewModel: DetectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            permissionStrip
            controls
            eventTable
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 480)
        .onAppear {
            viewModel.refreshPermissions()
            viewModel.beginEventObservation()
        }
        .onDisappear {
            viewModel.endEventObservation()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Yan Tuş Tanılama")
                .font(.system(size: 28, weight: .semibold))
            Text("Arka planda çalışan CoreGraphics remap izleyicisi")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionStrip: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
            GridRow {
                PermissionBadge(
                    title: "Giriş İzleme",
                    state: viewModel.permissionSnapshot.listening
                )
                PermissionBadge(
                    title: "Remap",
                    state: viewModel.remapPermissionState,
                    detail: viewModel.futureRemapSummary
                )
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.requestListeningPermission()
            } label: {
                Label("İzin İste", systemImage: "hand.raised")
            }

            Button {
                viewModel.openInputMonitoringSettings()
            } label: {
                Label("Ayarlar", systemImage: "gear")
            }

            Button {
                viewModel.refreshPermissions()
            } label: {
                Label("Yenile", systemImage: "arrow.clockwise")
            }

            Divider()
                .frame(height: 24)

            Button {
                viewModel.startDetection()
            } label: {
                Label("Başlat", systemImage: "play.fill")
            }
            .disabled(!viewModel.canStartDetection)

            Button {
                viewModel.stopDetection()
            } label: {
                Label("Durdur", systemImage: "stop.fill")
            }
            .disabled(!viewModel.isRunning)

            Button {
                viewModel.clearEvents()
            } label: {
                Label("Temizle", systemImage: "trash")
            }
            .disabled(viewModel.events.isEmpty)

            Spacer()

            StatusPill(isRunning: viewModel.isRunning)
        }
    }

    private var eventTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let lastErrorMessage = viewModel.lastErrorMessage {
                Label(lastErrorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }

            Table(viewModel.events) {
                TableColumn("Tuş") { event in
                    Text(event.buttonNumber)
                        .font(.system(.body, design: .monospaced))
                }
                TableColumn("Faz", value: \.phase)
                TableColumn("Zaman", value: \.timestamp)
                TableColumn("Konum", value: \.location)
            }
        }
    }
}

private struct PermissionBadge: View {
    let title: String
    let state: InputPermissionState
    var detail: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: state.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(state.isGranted ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail ?? label)
                    .font(.callout.weight(.medium))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private var label: String {
        switch state {
        case .unknown:
            "Bilinmiyor"
        case .granted:
            "Verildi"
        case .missing:
            "Eksik"
        }
    }
}

private struct StatusPill: View {
    let isRunning: Bool

    var body: some View {
        Label(isRunning ? "Çalışıyor" : "Durdu", systemImage: isRunning ? "waveform" : "pause.fill")
            .font(.callout.weight(.medium))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isRunning ? .green.opacity(0.14) : .secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isRunning ? .green : .secondary)
    }
}

#Preview {
    ContentView(viewModel: AppContainer().detectionViewModel)
}
