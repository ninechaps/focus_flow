import SwiftUI

/// Observable state model shared between StatusBarController and SwiftUI view.
/// Updated from Dart via MethodChannel.
class PopoverState: ObservableObject {
    @Published var focusState: String = "idle"
    @Published var taskName: String = ""
    @Published var formattedTime: String = "00:00"
    @Published var progress: Double = 0.0
    @Published var timerMode: String = "countdown"
    @Published var sessionTime: String = "00:00"
    @Published var totalTime: String = "00:00"
    @Published var sessions: Int = 0
    @Published var breadcrumb: String? = nil

    var isActive: Bool {
        focusState == "running" || focusState == "paused"
    }

    var isRunning: Bool {
        focusState == "running"
    }

    var isPaused: Bool {
        focusState == "paused"
    }

    var isIdle: Bool {
        focusState == "idle"
    }

    var isReady: Bool {
        focusState == "ready"
    }

    var isCompleted: Bool {
        focusState == "completed"
    }
}

/// SwiftUI view displayed inside the NSPopover when left-clicking the tray icon.
struct FocusPopoverView: View {
    @ObservedObject var state: PopoverState
    let onAction: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if state.isActive || state.isReady || state.isCompleted {
                activeContent
            } else {
                idleContent
            }

            Divider()

            openAppButton
        }
        .frame(width: 300)
    }

    // MARK: - Active Content

    private var activeContent: some View {
        VStack(spacing: 0) {
            // Task info header
            taskHeader
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            // Timer ring
            timerRing
                .padding(.vertical, 20)

            // Control buttons
            if state.isActive || state.isReady {
                controlButtons
                    .padding(.bottom, 16)
            }

            Divider()

            // Session stats
            sessionStats
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
        }
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(state.taskName.isEmpty ? "Focus Session" : state.taskName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }

            if let breadcrumb = state.breadcrumb, !breadcrumb.isEmpty {
                Text(breadcrumb)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var timerRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: state.progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: state.progress)

            // Time text
            VStack(spacing: 2) {
                Text(state.formattedTime)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))

                Text(statusLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 12) {
            if state.isRunning {
                actionButton(title: "⏸ 暂停", action: "pause")
                actionButton(title: "⏹ 停止", action: "stop", isDestructive: true)
            } else if state.isPaused {
                actionButton(title: "▶ 继续", action: "resume")
                actionButton(title: "⏹ 停止", action: "stop", isDestructive: true)
            } else if state.isReady {
                actionButton(title: "▶ 开始", action: "start")
            }
        }
    }

    private func actionButton(title: String, action: String, isDestructive: Bool = false) -> some View {
        Button(action: { onAction(action) }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isDestructive ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                .foregroundColor(isDestructive ? .red : .accentColor)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var sessionStats: some View {
        VStack(spacing: 6) {
            statRow(label: "本次会话", value: state.sessionTime)
            statRow(label: "累计专注", value: state.totalTime)
            statRow(label: "完成次数", value: "\(state.sessions)")
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("🍅")
                .font(.system(size: 40))

            Text("Focus Hut")
                .font(.system(size: 18, weight: .semibold))

            Text("暂无进行中的专注")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(height: 200)
    }

    // MARK: - Open App Button

    private var openAppButton: some View {
        Button(action: { onAction("showWindow") }) {
            HStack {
                Spacer()
                Text("打开 Focus Hut")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch state.focusState {
        case "running": return .green
        case "paused": return .orange
        case "ready": return .blue
        case "completed": return .green
        default: return .gray
        }
    }

    private var progressColor: Color {
        switch state.focusState {
        case "running": return .green
        case "paused": return .orange
        default: return .accentColor
        }
    }

    private var statusLabel: String {
        switch state.focusState {
        case "running": return "专注中"
        case "paused": return "已暂停"
        case "ready": return "准备就绪"
        case "completed": return "已完成"
        default: return ""
        }
    }
}
