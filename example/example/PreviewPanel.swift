import SwiftUI
import JSONRenderSwift

struct PreviewPanel: View {
    let spec: Spec?
    let json: String

    @State private var selectedTab = PreviewTab.liveRender

    enum PreviewTab: String, CaseIterable {
        case json = "JSON"
        case liveRender = "Live Render"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(PreviewTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            Group {
                switch selectedTab {
                case .json:
                    jsonView
                case .liveRender:
                    liveRenderView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var jsonView: some View {
        Group {
            if json.isEmpty {
                ContentUnavailableView(
                    "No JSON Yet",
                    systemImage: "curlybraces",
                    description: Text("Send a message to generate UI")
                )
            } else {
                ScrollView {
                    Text(json)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    private var liveRenderView: some View {
        Group {
            if let spec {
                ScrollView {
                    JSONRenderer(spec: spec)
                        .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Preview",
                    systemImage: "rectangle.dashed",
                    description: Text("Send a message to generate UI")
                )
            }
        }
    }
}
