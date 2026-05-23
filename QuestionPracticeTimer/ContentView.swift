import SwiftUI
import AppKit
import Combine
import Charts
import UniformTypeIdentifiers

// MARK: - 1. Analytics Data Model
struct QuestionLap: Identifiable {
    let id = UUID()
    let questionNumber: Int
    let duration: TimeInterval
}

// MARK: - 2. Dedicated Key Registry Choices
enum PracticeKey: String, CaseIterable, Identifiable, Codable {
    case lShift = "Left Shift"
    case rShift = "Right Shift"
    case lCmd = "Left Command"
    case rCmd = "Right Command"
    case lOpt = "Left Option"
    case rOpt = "Right Option"
    case tab = "Tab"
    case backslash = "Backslash (\\)"
    
    var id: String { self.rawValue }
    
    // Checks if a given event matches this specific choice
    func matches(event: NSEvent) -> Bool {
        switch self {
        case .tab:
            return event.type == .keyDown && event.keyCode == 48
        case .backslash:
            return event.type == .keyDown && event.keyCode == 42
        case .lShift:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0002))
        case .rShift:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0004))
        case .lCmd:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0008))
        case .rCmd:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0010))
        case .lOpt:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0020))
        case .rOpt:
            return event.type == .flagsChanged && event.modifierFlags.contains(.init(rawValue: 0x0040))
        }
    }
}

// MARK: - 3. Always-On-Top Window Architecture
class TimerWindowController: NSWindowController {
    convenience init(rootView: AnyView) {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 280, height: 160),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        window.contentView = NSHostingView(rootView: rootView)
        self.init(window: window)
    }
}

// MARK: - 4. Floating Timer HUD Engine View
struct FloatingTimerView: View {
    @State private var currentStopwatch: TimeInterval = 0
    @State private var totalTimeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var laps: [QuestionLap] = []
    @State private var currentQuestionIndex = 1
    @State private var showSettings = false
    
    // Configurable Key Selection Storage (Saved automatically)
    @AppStorage("key_startNext") private var startNextKey: PracticeKey = .rShift
    @AppStorage("key_pause") private var pauseKey: PracticeKey = .lShift
    @AppStorage("key_stop") private var stopKey: PracticeKey = .backslash
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 4) {
            // Settings Header Bar Toggle
            HStack {
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: showSettings ? "chevron.up.circle.fill" : "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding([.top, .trailing], 6)
            }
            
            if showSettings {
                // Simplified Settings Grid Row Selections
                VStack(spacing: 6) {
                    HStack {
                        Text("Start / Next:").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $startNextKey) {
                            ForEach(PracticeKey.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden().frame(width: 130)
                    }
                    HStack {
                        Text("Pause / Resume:").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $pauseKey) {
                            ForEach(PracticeKey.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden().frame(width: 130)
                    }
                    HStack {
                        Text("End Session:").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $stopKey) {
                            ForEach(PracticeKey.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden().frame(width: 130)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Main Active Timer Layout
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Q\(currentQuestionIndex):")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(formatStopwatch(currentStopwatch))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text("Total: \(formatTotalTime(totalTimeElapsed))")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundColor(.gray)
                    
                    Circle()
                        .fill(isRunning ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                        .padding(.top, 4)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer()
        }
        .frame(width: 260, height: showSettings ? 140 : 105)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).cornerRadius(16))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSettings)
        .onReceive(timer) { _ in
            guard isRunning else { return }
            currentStopwatch += 0.01
            totalTimeElapsed += 0.01
        }
        .onAppear {
            setupGlobalHotkeyListeners()
        }
    }
    
    // MARK: - Simplified Hotkey System Listening
    private func setupGlobalHotkeyListeners() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            self.evaluateEvent(event: event)
        }
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            self.evaluateEvent(event: event)
            return event
        }
    }
    
    private func evaluateEvent(event: NSEvent) {
        // Prevent hotkey actions from misfiring while you are adjusting settings
        guard !showSettings else { return }
        
        if stopKey.matches(event: event) {
            if totalTimeElapsed > 0 { stopAndShowInsights() }
        } else if startNextKey.matches(event: event) {
            if !isRunning && currentStopwatch == 0 {
                isRunning = true
            } else if isRunning {
                recordLapAndNext()
            }
        } else if pauseKey.matches(event: event) {
            if totalTimeElapsed > 0 { isRunning.toggle() }
        }
    }
    
    private func recordLapAndNext() {
        guard currentStopwatch > 0.2 else { return }
        let newLap = QuestionLap(questionNumber: currentQuestionIndex, duration: currentStopwatch)
        laps.append(newLap)
        currentStopwatch = 0
        currentQuestionIndex += 1
    }
    
    private func stopAndShowInsights() {
        isRunning = false
        if currentStopwatch > 0.2 { recordLapAndNext() }
        
        let analyticsView = AnalyticsView(laps: laps, totalDuration: totalTimeElapsed)
        let analyticsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        analyticsWindow.title = "Practice Session Performance Insights"
        analyticsWindow.center()
        analyticsWindow.isReleasedWhenClosed = false
        analyticsWindow.contentView = NSHostingView(rootView: analyticsView)
        analyticsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        currentStopwatch = 0
        totalTimeElapsed = 0
        currentQuestionIndex = 1
        laps = []
    }
    
    private func formatStopwatch(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenthsOfASecond = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d:%1d", minutes, seconds, tenthsOfASecond)
    }
    
    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - 5. Session Analytics Window & Screenshot Engine
struct AnalyticsView: View {
    let laps: [QuestionLap]
    let totalDuration: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Session Summary Insights").font(.title).fontWeight(.bold)
                Spacer()
                Button(action: { captureDashboardScreenshot() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                        Text("Save Screenshot")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
            }
            
            if laps.isEmpty {
                Text("No question tracking loops finished this execution run.").foregroundColor(.gray)
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        MetricCard(title: "Total Questions Solved", value: "\(laps.count)", icon: "doc.plaintext", color: .blue)
                        MetricCard(title: "Average Velocity / Question", value: formatInterval(totalDuration / Double(laps.count)), icon: "speedometer", color: .green)
                    }
                    HStack(spacing: 12) {
                        if let fastest = laps.min(by: { $0.duration < $1.duration }) {
                            MetricCard(title: "Highest Velocity (Fastest)", value: "Q\(fastest.questionNumber) (\(formatInterval(fastest.duration)))", icon: "bolt.fill", color: .yellow)
                        }
                        if let slowest = laps.max(by: { $0.duration < $1.duration }) {
                            MetricCard(title: "Lowest Velocity (Slowest)", value: "Q\(slowest.questionNumber) (\(formatInterval(slowest.duration)))", icon: "exclamationmark.triangle.fill", color: .red)
                        }
                    }
                }
                
                Text("Time Expended Velocity Graph").font(.headline).padding(.top, 6)
                
                Chart {
                    ForEach(laps) { lap in
                        BarMark(
                            x: .value("Question", "Q\(lap.questionNumber)"),
                            y: .value("Seconds", lap.duration)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .annotation(position: .top) {
                            Text(String(format: "%.1fs", lap.duration)).font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(24)
        .frame(width: 620, height: 500)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return "\(mins)m \(secs)s"
    }
    
    private func captureDashboardScreenshot() {
        guard let window = NSApp.keyWindow else { return }
        let viewView = window.contentView
        let rect = viewView?.bounds ?? .zero
        guard let bitmapRep = viewView?.bitmapImageRepForCachingDisplay(in: rect) else { return }
        viewView?.cacheDisplay(in: rect, to: bitmapRep)
        guard let imageProps = bitmapRep.representation(using: .png, properties: [:]) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Practice_Metrics_\(Int(Date().timeIntervalSince1970)).png"
        
        savePanel.begin { response in
            if response == .OK, let targetURL = savePanel.url {
                try? imageProps.write(to: targetURL)
            }
        }
    }
}

// MARK: - 6. Layout UI Decorators
struct MetricCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline).fontWeight(.bold)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView(); view.material = material; view.blendingMode = blendingMode; view.state = .active; return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
