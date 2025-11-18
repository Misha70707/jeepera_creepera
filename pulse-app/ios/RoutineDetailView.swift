import SwiftUI

// MARK: - Routine Detail View (Execution)
struct RoutineDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: RoutineDetailViewModel
    @State private var showConfetti = false

    init(routine: Routine) {
        _viewModel = StateObject(wrappedValue: RoutineDetailViewModel(routine: routine))
    }

    var allTasksComplete: Bool {
        viewModel.tasks.allSatisfy { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseDarkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Text(viewModel.routine.emoji)
                                            .font(.system(size: 36))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(viewModel.routine.name)
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.pulseText)

                                            Text("Started at \(viewModel.startTime.formattedTime)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.pulseSecondary)
                                        }
                                    }

                                    Spacer()
                                }

                                Spacer()
                            }

                            // Progress Bar
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Progress: \(viewModel.completedCount)/\(viewModel.tasks.count) tasks")
                                        .font(.system(size: 12))
                                        .foregroundColor(.pulseSecondary)

                                    Spacer()

                                    Text(viewModel.progressPercent.percentageString)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.pulseAccent)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.pulseSeparator)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.pulseAccent)
                                            .frame(width: geometry.size.width * viewModel.progressPercent)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding(16)
                        .background(Color.pulseSurface)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        // MARK: - Tasks List
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                                TaskItemView(
                                    task: task,
                                    isCurrentTask: index == viewModel.currentTaskIndex,
                                    onToggle: { viewModel.toggleTask(task) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // MARK: - Timer for Current Task (if applicable)
                        if let currentTask = viewModel.currentTask,
                           let duration = currentTask.estimatedDuration,
                           !currentTask.isCompleted {
                            TimerCardView(
                                taskName: currentTask.name,
                                duration: duration,
                                onComplete: { viewModel.toggleTask(currentTask) }
                            )
                            .padding(.horizontal, 16)
                        }

                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: { viewModel.skipCurrentTask() }) {
                                    Text("Skip Task")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundColor(.pulseSecondary)
                                        .background(Color.pulseSurface)
                                        .cornerRadius(8)
                                }

                                if allTasksComplete {
                                    Button(action: {
                                        viewModel.completeRoutine()
                                        showConfetti = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            dismiss()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("🎉 Finish Routine")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .foregroundColor(.pulseDarkBg)
                                        .background(Color.pulseSuccess)
                                        .cornerRadius(8)
                                    }
                                } else {
                                    Button(action: { viewModel.skipCurrentTask() }) {
                                        Text("Next Task")
                                            .font(.system(size: 14, weight: .semibold))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .foregroundColor(.pulseDarkBg)
                                            .background(Color.pulseAccent)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            Button(action: { dismiss() }) {
                                Text("Close")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .foregroundColor(.pulseSecondary)
                                    .background(Color.pulseSurface)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 16)
                }

                // Confetti Animation
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Routine Execution")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - View Model
class RoutineDetailViewModel: ObservableObject {
    @Published var routine: Routine
    @Published var tasks: [RoutineTask]
    @Published var startTime: Date = Date()
    @Published var currentTaskIndex: Int = 0

    init(routine: Routine) {
        self.routine = routine
        self.tasks = routine.tasks

        // Find first incomplete task
        if let index = tasks.firstIndex(where: { !$0.isCompleted }) {
            self.currentTaskIndex = index
        }
    }

    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var progressPercent: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    var currentTask: RoutineTask? {
        guard currentTaskIndex < tasks.count else { return nil }
        return tasks[currentTaskIndex]
    }

    func toggleTask(_ task: RoutineTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            if tasks[index].isCompleted {
                tasks[index].completedAt = Date()
            }

            // Move to next incomplete task
            if let nextIndex = tasks.firstIndex(where: { !$0.isCompleted && tasks.firstIndex(of: $0)! > currentTaskIndex }) {
                currentTaskIndex = nextIndex
            }

            AnalyticsService.shared.logEvent("task_toggled", properties: ["task": task.name])
        }
    }

    func skipCurrentTask() {
        if currentTaskIndex < tasks.count - 1 {
            currentTaskIndex += 1
        }
    }

    func completeRoutine() {
        // Mark all incomplete tasks as complete
        for i in 0..<tasks.count {
            if !tasks[i].isCompleted {
                tasks[i].isCompleted = true
                tasks[i].completedAt = Date()
            }
        }

        AnalyticsService.shared.logEvent("routine_completed", properties: [
            "name": routine.name,
            "task_count": tasks.count,
            "duration_minutes": Int(Date().timeIntervalSince(startTime) / 60)
        ])
    }
}

// MARK: - Task Item View
struct TaskItemView: View {
    let task: RoutineTask
    let isCurrentTask: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isCompleted ? .pulseSuccess : (isCurrentTask ? .pulseAccent : .pulseSeparator))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pulseText)
                        .strikethrough(task.isCompleted)

                    if let duration = task.estimatedDuration {
                        Text("Est. \(duration / 60) min")
                            .font(.system(size: 12))
                            .foregroundColor(.pulseSecondary)
                    }
                }

                Spacer()

                if let completedAt = task.completedAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("✓")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.pulseSuccess)

                        Text(completedAt.formattedTime)
                            .font(.system(size: 10))
                            .foregroundColor(.pulseSecondary)
                    }
                }
            }

            if let description = task.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.pulseSecondary)
            }
        }
        .padding(12)
        .background(isCurrentTask ? Color.pulseSurface.opacity(0.8) : Color.pulseSurface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentTask ? Color.pulseAccent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Timer Card View
struct TimerCardView: View {
    let taskName: String
    let duration: TimeInterval
    let onComplete: () -> Void

    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var isRunning = false

    init(taskName: String, duration: TimeInterval, onComplete: @escaping () -> Void) {
        self.taskName = taskName
        self.duration = duration
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: duration)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Timer for \(taskName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pulseSecondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseSecondary)

                    Text(formattedTime)
                        .font(.system(size: 32, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(.pulseAccent)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.pulseAccent)
                            .foregroundColor(.pulseDarkBg)
                            .cornerRadius(8)
                    }

                    Button(action: { timeRemaining = duration }) {
                        Text("Reset")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .foregroundColor(.pulseSecondary)
                            .background(Color.pulseSurface)
                            .cornerRadius(6)
                    }
                }
            }

            Button(action: {
                isRunning = false
                timeRemaining = 0
                onComplete()
            }) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(.pulseDarkBg)
                    .background(Color.pulseSuccess)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.pulseSurface)
        .cornerRadius(12)
    }

    private func toggleTimer() {
        isRunning.toggle()

        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    isRunning = false
                    onComplete()
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            createConfetti()
        }
    }

    private func createConfetti() {
        let emojis = ["🎉", "🎊", "⭐", "✨", "🎈"]
        for _ in 0..<30 {
            let randomEmoji = emojis.randomElement()!
            let piece = ConfettiPiece(
                emoji: randomEmoji,
                position: CGPoint(
                    x: CGFloat.random(in: 0...400),
                    y: -50
                ),
                size: CGFloat.random(in: 16...32),
                opacity: 1.0
            )
            confetti.append(piece)

            withAnimation(.easeInOut(duration: 2)) {
                var updated = piece
                updated.position.y = 850
                updated.opacity = 0
                if let index = confetti.firstIndex(where: { $0.id == piece.id }) {
                    confetti[index] = updated
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}

// MARK: - Preview
#Preview {
    RoutineDetailView(routine: Routine.mockRoutines[0])
}
