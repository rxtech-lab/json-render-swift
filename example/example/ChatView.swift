import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                emptyState
            } else {
                messageList
            }
            inputBar
        }
        .background(Color(.windowBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Describe your UI")
                .font(.title2)
                .fontWeight(.medium)

            Text("Tell me what interface you'd like to create\nand I'll generate it for you.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isGenerating {
                        GeneratingIndicator()
                            .id("loading")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isGenerating) {
                if viewModel.isGenerating {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Describe what you want to build…", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1 ... 5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(isInputFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
                    .onSubmit {
                        guard !viewModel.isGenerating else { return }
                        Task { await viewModel.send() }
                    }

                Button {
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(sendButtonEnabled ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!sendButtonEnabled)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }

    private var sendButtonEnabled: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating
    }
}

struct GeneratingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Assistant")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(0 ..< 3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }

                    Text("Generating UI")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .onAppear {
            isAnimating = true
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer(minLength: 48)
                userMessage
            } else {
                assistantMessage
                Spacer(minLength: 48)
            }
        }
    }

    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var assistantMessage: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                Text("Assistant")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
                    .foregroundStyle(foregroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var avatar: some View {
        Circle()
            .fill(avatarGradient)
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: avatarIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    private var avatarGradient: LinearGradient {
        switch message.role {
        case .user:
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .assistant:
            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .error:
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var avatarIcon: String {
        switch message.role {
        case .user: "person.fill"
        case .assistant: "sparkles"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user: .accentColor
        case .assistant: Color(.controlBackgroundColor)
        case .error: .red.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch message.role {
        case .user: .white
        case .assistant: .primary
        case .error: .red
        }
    }
}

#Preview("Empty State") {
    ChatView(viewModel: ChatViewModel())
        .frame(width: 400, height: 500)
}

#Preview("With Messages") {
    let viewModel = ChatViewModel()
    viewModel.messages = [
        ChatMessage(role: .user, content: "Create a login form with email and password fields"),
        ChatMessage(role: .assistant, content: "UI generated successfully."),
        ChatMessage(role: .user, content: "Add a forgot password link below the form")
    ]
    return ChatView(viewModel: viewModel)
        .frame(width: 400, height: 500)
}
