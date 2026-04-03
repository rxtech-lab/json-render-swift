// JSONRenderSwift — A SwiftUI Generative UI framework
// Render AI-generated JSON specs as native SwiftUI views.

// Re-export all public types

// Models
@_exported import struct Foundation.URL

// The public API surface:
//
// Types:
//   - Spec, UIElement           — JSON spec model
//   - PropValue                  — Property values (literal or expression)
//   - JSONValue                  — Type-erased JSON value
//   - JSONPointer                — RFC 6901 JSON Pointer
//   - VisibilityCondition        — Conditional rendering
//   - RepeatConfig               — Array iteration
//   - ActionBinding              — Event -> action binding
//
// State:
//   - StateStore                 — Centralized @Observable state
//   - StateBackend               — Protocol for custom backends
//   - LocalStateBackend          — In-memory state
//
// Rendering:
//   - JSONRenderer               — Top-level SwiftUI view
//   - ComponentRegistry          — Component type -> view mapping
//   - ComponentRenderContext      — Context passed to render functions
//   - ComponentRenderFn           — Type alias for render functions
//
// Actions:
//   - ActionExecutor             — Action dispatch
//
// Resolution:
//   - PropResolver               — Resolve expressions to values
//   - VisibilityEvaluator        — Evaluate visibility conditions
//   - TemplateInterpolator       — Template string interpolation
//   - ResolutionContext           — Context for resolution
