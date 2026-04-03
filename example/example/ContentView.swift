//
//  ContentView.swift
//  example
//
//  Created by Qiwei Li on 4/4/26.
//

import SwiftUI
import JSONRenderSwift

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @AppStorage("providerType") private var providerType: String = AIProviderType.openai.rawValue
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @AppStorage("modelName") private var modelName: String = ""
    @AppStorage("apiKey") private var apiKey: String = ""

    private var isConfigured: Bool {
        let provider = AIProviderType(rawValue: providerType) ?? .openai
        switch provider {
        case .openai:
            return !modelName.isEmpty && !apiKey.isEmpty
        case .openaiCompatible:
            return !modelName.isEmpty && !apiEndpoint.isEmpty && !apiKey.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !isConfigured {
                    notConfiguredView
                } else {
                    mainView
                }
            }
            .frame(minWidth: 900, minHeight: 600)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Label("New Chat", systemImage: "plus")
                    }
                    .disabled(!isConfigured)
                }
            }
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear.badge")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("AI Model Not Configured")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Set up your AI provider, API key, and model in Settings.")
                .foregroundStyle(.secondary)
            SettingsLink {
                Text("Open Settings…")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainView: some View {
        HSplitView {
            ChatView(viewModel: viewModel)
                .frame(minWidth: 350)

            PreviewPanel(spec: viewModel.currentSpec, json: viewModel.currentJSON)
                .frame(minWidth: 400)
        }
    }
}

#Preview {
    ContentView()
}
