import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: DetectionViewModel
    var onOpenDiagnostics: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            hero
            cards
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 116, height: 116)
                    .blur(radius: 6)
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 3) {
                Text("SideButtonControl")
                    .font(.title2.weight(.semibold))
                Text("Yan fare tuşlarına işlev ata")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 34)
        .padding(.bottom, 26)
    }

    private var cards: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(Array(viewModel.bindings.bindings.enumerated()), id: \.element.id) { index, binding in
                BindingCard(
                    index: index,
                    button: binding.button,
                    command: viewModel.bindings.command(for: binding.button),
                    onSelect: { viewModel.updateCommand($0, for: binding.button) }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.06), value: appeared)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
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

private struct BindingCard: View {
    let index: Int
    let button: MouseButtonID
    let command: SideButtonCommand
    var onSelect: (SideButtonCommand) -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(command.tint.opacity(0.14))
                    .frame(width: 58, height: 58)
                Image(systemName: command.symbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(command.tint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .animation(.easeOut(duration: 0.18), value: command)

            VStack(spacing: 2) {
                Text("Yan Tuş \(index + 1)")
                    .font(.headline)
                Text("Tuş \(button.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Menu {
                ForEach(SideButtonCommand.selectableCases, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        Label(option.displayName, systemImage: option.symbolName)
                    }
                }
            } label: {
                HStack {
                    Text(command.displayName)
                        .font(.callout.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView(viewModel: AppContainer().detectionViewModel, onOpenDiagnostics: {})
}
