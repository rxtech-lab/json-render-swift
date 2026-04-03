import SwiftUI

// MARK: - 1. Basic Card with Text

/// Demonstrates a simple Card containing text — the minimal json-render usage.
@available(iOS 17.0, macOS 14.0, *)
struct BasicCardPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "card",
                "elements": {
                    "card": {
                        "type": "Card",
                        "props": {"title": "Welcome", "subtitle": "Your first json-render spec"},
                        "children": ["msg"]
                    },
                    "msg": {
                        "type": "Text",
                        "props": {"content": "This UI was generated from JSON."}
                    }
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    var body: some View {
        JSONRenderer(spec: spec)
            .padding()
    }
}

// MARK: - 2. Data Binding Form

/// Demonstrates two-way binding with TextField, Toggle, and template interpolation.
@available(iOS 17.0, macOS 14.0, *)
struct DataBindingFormPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "card",
                "elements": {
                    "card": {
                        "type": "Card",
                        "props": {"title": "Profile Form"},
                        "children": ["greeting", "nameField", "divider", "darkToggle", "statusBadge"]
                    },
                    "greeting": {
                        "type": "Text",
                        "props": {
                            "content": {"$template": "Hello, ${/user/name}!"},
                            "font": "title2",
                            "weight": "bold"
                        }
                    },
                    "nameField": {
                        "type": "TextField",
                        "props": {
                            "placeholder": "Enter your name",
                            "value": {"$bindState": "/user/name"}
                        }
                    },
                    "divider": {
                        "type": "Divider",
                        "props": {}
                    },
                    "darkToggle": {
                        "type": "Toggle",
                        "props": {
                            "label": "Dark Mode",
                            "isOn": {"$bindState": "/settings/darkMode"}
                        }
                    },
                    "statusBadge": {
                        "type": "Badge",
                        "props": {
                            "text": {"$cond": {"$state": "/settings/darkMode"}, "$then": "Dark", "$else": "Light"},
                            "color": {"$cond": {"$state": "/settings/darkMode"}, "$then": "purple", "$else": "orange"}
                        }
                    }
                },
                "state": {
                    "user": {"name": "World"},
                    "settings": {"darkMode": false}
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    var body: some View {
        JSONRenderer(spec: spec)
            .padding()
    }
}

// MARK: - 3. Visibility & Conditional Rendering

/// Demonstrates conditional visibility — elements appear/disappear based on state.
@available(iOS 17.0, macOS 14.0, *)
struct VisibilityPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "stack",
                "elements": {
                    "stack": {
                        "type": "VStack",
                        "props": {"spacing": 12},
                        "children": ["toggleBtn", "secretCard", "counterRow", "highCountMsg"]
                    },
                    "toggleBtn": {
                        "type": "Button",
                        "props": {"label": "Toggle Secret", "style": "bordered"},
                        "on": {
                            "press": {"action": "toggleState", "params": {"path": "/showSecret"}}
                        }
                    },
                    "secretCard": {
                        "type": "Card",
                        "props": {"title": "Secret Message", "padding": "lg"},
                        "children": ["secretText"],
                        "visible": {"$state": "/showSecret"}
                    },
                    "secretText": {
                        "type": "Text",
                        "props": {"content": "You found the hidden content!", "color": "green"}
                    },
                    "counterRow": {
                        "type": "HStack",
                        "props": {"spacing": 8},
                        "children": ["decBtn", "countLabel", "incBtn"]
                    },
                    "decBtn": {
                        "type": "Button",
                        "props": {"label": "−", "style": "bordered"},
                        "on": {
                            "press": {"action": "decrementState", "params": {"path": "/count"}}
                        }
                    },
                    "countLabel": {
                        "type": "Text",
                        "props": {
                            "content": {"$template": "Count: ${/count}"},
                            "font": "headline"
                        }
                    },
                    "incBtn": {
                        "type": "Button",
                        "props": {"label": "+", "style": "borderedProminent"},
                        "on": {
                            "press": {"action": "incrementState", "params": {"path": "/count"}}
                        }
                    },
                    "highCountMsg": {
                        "type": "Text",
                        "props": {"content": "Count is high! (≥ 5)", "color": "red", "weight": "bold"},
                        "visible": {"$state": "/count", "gte": 5}
                    }
                },
                "state": {
                    "showSecret": false,
                    "count": 0
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    @State private var store = StateStore(
        initialState: .object([
            "showSecret": .bool(false),
            "count": .int(0),
        ]))

    var body: some View {
        JSONRenderer(spec: spec, store: store)
            .padding()
    }
}

// MARK: - 4. Actions & Interactivity

/// Demonstrates actions: button presses mutate state, with custom action handlers.
@available(iOS 17.0, macOS 14.0, *)
struct ActionsPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "card",
                "elements": {
                    "card": {
                        "type": "Card",
                        "props": {"title": "Todo List"},
                        "children": ["inputRow", "divider", "list"]
                    },
                    "inputRow": {
                        "type": "HStack",
                        "props": {"spacing": 8},
                        "children": ["todoInput", "addBtn"]
                    },
                    "todoInput": {
                        "type": "TextField",
                        "props": {
                            "placeholder": "New todo...",
                            "value": {"$bindState": "/newTodo"}
                        }
                    },
                    "addBtn": {
                        "type": "Button",
                        "props": {"label": "Add", "style": "borderedProminent"},
                        "on": {
                            "press": {"action": "addTodo"}
                        }
                    },
                    "divider": {
                        "type": "Divider",
                        "props": {}
                    },
                    "list": {
                        "type": "VStack",
                        "props": {"alignment": "leading", "spacing": 4},
                        "children": ["todoItem"],
                        "repeat": {"statePath": "/todos", "key": "id"}
                    },
                    "todoItem": {
                        "type": "HStack",
                        "props": {},
                        "children": ["todoIcon", "todoText"]
                    },
                    "todoIcon": {
                        "type": "Image",
                        "props": {"systemName": "checkmark.circle", "color": "green"}
                    },
                    "todoText": {
                        "type": "Text",
                        "props": {"content": {"$item": "text"}}
                    }
                },
                "state": {
                    "newTodo": "",
                    "todos": [
                        {"id": "1", "text": "Learn JSONRenderSwift"},
                        {"id": "2", "text": "Build an AI-powered app"}
                    ]
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    @State private var store = StateStore(
        initialState: .object([
            "newTodo": .string(""),
            "todos": .array([
                .object(["id": .string("1"), "text": .string("Learn JSONRenderSwift")]),
                .object(["id": .string("2"), "text": .string("Build an AI-powered app")]),
            ]),
        ]))

    @State private var executor: ActionExecutor = {
        let exec = ActionExecutor()
        exec.register("addTodo") { params, store in
            guard let text = store.get("/newTodo")?.stringValue, !text.isEmpty else { return }
            let newItem: JSONValue = .object([
                "id": .string(UUID().uuidString),
                "text": .string(text),
            ])
            // Push to array
            let current = store.get("/todos")
            var arr: [JSONValue]
            if case .array(let existing) = current {
                arr = existing
            } else {
                arr = []
            }
            arr.append(newItem)
            store.set("/todos", value: .array(arr))
            store.set("/newTodo", value: .string(""))
        }
        return exec
    }()

    var body: some View {
        JSONRenderer(spec: spec, store: store, actionExecutor: executor)
            .padding()
    }
}

// MARK: - 5. Slider & Progress

/// Demonstrates Slider with two-way binding and ProgressView driven by state.
@available(iOS 17.0, macOS 14.0, *)
struct SliderProgressPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "card",
                "elements": {
                    "card": {
                        "type": "Card",
                        "props": {"title": "Download Progress"},
                        "children": ["progressBar", "slider", "label"]
                    },
                    "progressBar": {
                        "type": "ProgressView",
                        "props": {
                            "value": {"$state": "/progress"},
                            "total": 100
                        }
                    },
                    "slider": {
                        "type": "Slider",
                        "props": {
                            "value": {"$bindState": "/progress"},
                            "min": 0,
                            "max": 100,
                            "step": 1,
                            "label": "Progress"
                        }
                    },
                    "label": {
                        "type": "Text",
                        "props": {
                            "content": {"$template": "${/progress}% complete"},
                            "font": "caption",
                            "color": "secondary"
                        }
                    }
                },
                "state": {"progress": 35}
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    @State private var store = StateStore(
        initialState: .object([
            "progress": .double(35)
        ]))

    var body: some View {
        JSONRenderer(spec: spec, store: store)
            .padding()
    }
}

// MARK: - 6. Full Dashboard

/// Demonstrates a complex multi-component dashboard layout.
@available(iOS 17.0, macOS 14.0, *)
struct DashboardPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "vstack",
                "elements": {
                    "vstack": {
                        "type": "VStack",
                        "props": {"spacing": 16},
                        "children": ["header", "metrics", "divider", "settingsCard"]
                    },
                    "header": {
                        "type": "HStack",
                        "props": {},
                        "children": ["title", "spacer", "statusBadge"]
                    },
                    "title": {
                        "type": "Text",
                        "props": {"content": "Dashboard", "font": "largeTitle", "weight": "bold"}
                    },
                    "spacer": {
                        "type": "Spacer",
                        "props": {}
                    },
                    "statusBadge": {
                        "type": "Badge",
                        "props": {"text": "Online", "color": "green"}
                    },
                    "metrics": {
                        "type": "HStack",
                        "props": {"spacing": 12},
                        "children": ["usersCard", "revenueCard"]
                    },
                    "usersCard": {
                        "type": "Card",
                        "props": {"title": "Users"},
                        "children": ["usersCount"]
                    },
                    "usersCount": {
                        "type": "Text",
                        "props": {
                            "content": {"$template": "${/metrics/users}"},
                            "font": "title",
                            "weight": "bold",
                            "color": "blue"
                        }
                    },
                    "revenueCard": {
                        "type": "Card",
                        "props": {"title": "Revenue"},
                        "children": ["revenueAmount"]
                    },
                    "revenueAmount": {
                        "type": "Text",
                        "props": {
                            "content": {"$template": "$${/metrics/revenue}"},
                            "font": "title",
                            "weight": "bold",
                            "color": "green"
                        }
                    },
                    "divider": {
                        "type": "Divider",
                        "props": {}
                    },
                    "settingsCard": {
                        "type": "Card",
                        "props": {"title": "Settings"},
                        "children": ["notifToggle", "analyticsToggle"]
                    },
                    "notifToggle": {
                        "type": "Toggle",
                        "props": {
                            "label": "Notifications",
                            "isOn": {"$bindState": "/settings/notifications"}
                        }
                    },
                    "analyticsToggle": {
                        "type": "Toggle",
                        "props": {
                            "label": "Analytics",
                            "isOn": {"$bindState": "/settings/analytics"}
                        }
                    }
                },
                "state": {
                    "metrics": {"users": 1247, "revenue": 52300},
                    "settings": {"notifications": true, "analytics": false}
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    var body: some View {
        JSONRenderer(spec: spec)
            .padding()
    }
}

// MARK: - 7. Form (grouped style)

/// Demonstrates the Form component with grouped style — TextField, Toggle, Slider inside a Form.
@available(iOS 17.0, macOS 14.0, *)
struct FormPreview: View {
    private let spec: Spec = {
        let json = """
            {
                "root": "form",
                "elements": {
                    "form": {
                        "type": "Form",
                        "props": {},
                        "children": ["profileSection", "prefsSection"]
                    },
                    "profileSection": {
                        "type": "Section",
                        "props": {"header": "Profile"},
                        "children": ["nameField", "emailField"]
                    },
                    "nameField": {
                        "type": "TextField",
                        "props": {
                            "placeholder": "Full name",
                            "value": {"$bindState": "/profile/name"}
                        }
                    },
                    "emailField": {
                        "type": "TextField",
                        "props": {
                            "placeholder": "Email address",
                            "value": {"$bindState": "/profile/email"}
                        }
                    },
                    "prefsSection": {
                        "type": "Section",
                        "props": {"header": "Preferences", "footer": "Adjust your notification and volume settings."},
                        "children": ["notifToggle", "volumeSlider"]
                    },
                    "notifToggle": {
                        "type": "Toggle",
                        "props": {
                            "label": "Enable notifications",
                            "isOn": {"$bindState": "/profile/notifications"}
                        }
                    },
                    "volumeSlider": {
                        "type": "Slider",
                        "props": {
                            "label": "Volume",
                            "value": {"$bindState": "/profile/volume"},
                            "min": 0,
                            "max": 100,
                            "step": 1
                        }
                    }
                },
                "state": {
                    "profile": {
                        "name": "Alice",
                        "email": "alice@example.com",
                        "notifications": true,
                        "volume": 75
                    }
                }
            }
            """
        return try! JSONDecoder().decode(Spec.self, from: json.data(using: .utf8)!)
    }()

    var body: some View {
        JSONRenderer(spec: spec)
    }
}

// MARK: - Previews

@available(iOS 17.0, macOS 14.0, *)
#Preview("1. Basic Card") {
    BasicCardPreview()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("2. Data Binding Form") {
    DataBindingFormPreview()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("3. Visibility & Conditions") {
    ScrollView {
        VisibilityPreview()
    }
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("4. Actions (Todo List)") {
    ActionsPreview()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("5. Slider & Progress") {
    SliderProgressPreview()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("6. Full Dashboard") {
    ScrollView {
        DashboardPreview()
    }
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("7. Form (Grouped)") {
    FormPreview()
}
