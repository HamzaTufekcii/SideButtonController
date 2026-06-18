import SwiftUI

struct DeathAdderStyleMouseHero: View {
    let bindings: [ButtonBinding]
    var commandFor: (MouseButtonID) -> SideButtonCommand
    var onSelect: (SideButtonCommand, MouseButtonID) -> Void

    private var visibleBindings: [(offset: Int, element: ButtonBinding)] {
        Array(bindings.prefix(2).enumerated())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("DeathAdderV2Mouse")
                .resizable()
                .scaledToFit()
                .frame(width: 388, height: 260)
                .position(x: 300, y: 124)
                .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 12)
                .accessibilityHidden(true)

            ForEach(visibleBindings, id: \.element.id) { index, binding in
                MouseButtonConnector(
                    start: CGPoint(x: 148, y: index == 0 ? 88 : 144),
                    end: CGPoint(x: index == 0 ? 246 : 238, y: index == 0 ? 116 : 152),
                    lift: index == 0 ? -16 : 14
                )
                .stroke(.secondary.opacity(0.56), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

                MouseButtonCallout(
                    index: index,
                    button: binding.button,
                    command: commandFor(binding.button),
                    onSelect: { onSelect($0, binding.button) }
                )
                .frame(width: 144, height: 58)
                .position(x: 74, y: index == 0 ? 88 : 144)
            }
        }
        .frame(width: 476, height: 246)
        .accessibilityElement(children: .contain)
    }
}

private struct MouseButtonCallout: View {
    let index: Int
    let button: MouseButtonID
    let command: SideButtonCommand
    var onSelect: (SideButtonCommand) -> Void

    var body: some View {
        Menu {
            ForEach(SideButtonCommand.selectableCases, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Label(option.displayName, systemImage: option.symbolName)
                }
            }
        } label: {
            HStack(spacing: 9) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Yan Tuş \(index + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Label(command.displayName, systemImage: command.symbolName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(command.tint)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                        .contentTransition(.symbolEffect(.replace))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(command.tint.opacity(0.3), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .accessibilityLabel("Yan Tuş \(index + 1), Tuş \(button.description), \(command.displayName)")
        .animation(.easeOut(duration: 0.18), value: command)
    }
}

private struct MouseButtonConnector: Shape {
    let start: CGPoint
    let end: CGPoint
    let lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let control1 = CGPoint(x: start.x + 42, y: start.y + lift)
        let control2 = CGPoint(x: end.x - 44, y: end.y)

        path.move(to: start)
        path.addCurve(
            to: end,
            control1: control1,
            control2: control2
        )

        return path
    }
}
