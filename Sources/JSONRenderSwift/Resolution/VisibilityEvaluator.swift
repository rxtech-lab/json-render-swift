import Foundation

/// Context for evaluating visibility conditions and resolving props.
public struct ResolutionContext: Sendable {
    public let state: JSONValue
    public let repeatItem: JSONValue?
    public let repeatIndex: Int?

    public init(state: JSONValue, repeatItem: JSONValue? = nil, repeatIndex: Int? = nil) {
        self.state = state
        self.repeatItem = repeatItem
        self.repeatIndex = repeatIndex
    }
}

/// Evaluates visibility conditions against the current state and repeat context.
public struct VisibilityEvaluator {
    /// Evaluate whether an element should be visible.
    public static func evaluate(_ condition: VisibilityCondition?, context: ResolutionContext) -> Bool {
        guard let condition else { return true }
        return evaluateCondition(condition, context: context)
    }

    private static func evaluateCondition(_ condition: VisibilityCondition, context: ResolutionContext) -> Bool {
        switch condition {
        case .literal(let value):
            return value

        case .single(let single):
            return evaluateSingle(single, context: context)

        case .allOf(let conditions):
            return conditions.allSatisfy { evaluateCondition($0, context: context) }

        case .and(let conditions):
            return conditions.allSatisfy { evaluateCondition($0, context: context) }

        case .or(let conditions):
            return conditions.contains { evaluateCondition($0, context: context) }
        }
    }

    private static func evaluateSingle(_ condition: SingleCondition, context: ResolutionContext) -> Bool {
        // Get the source value
        let sourceValue: JSONValue?
        switch condition.source {
        case .state(let path):
            sourceValue = JSONPointer(path).resolve(in: context.state)
        case .item(let field):
            if let item = context.repeatItem {
                if field.isEmpty {
                    sourceValue = item
                } else {
                    sourceValue = JSONPointer("/\(field)").resolve(in: item)
                }
            } else {
                sourceValue = nil
            }
        case .index:
            if let idx = context.repeatIndex {
                sourceValue = .int(idx)
            } else {
                sourceValue = nil
            }
        }

        let ops = condition.operators
        var result: Bool

        if ops.hasOperators {
            // Evaluate operators in precedence order
            result = true

            if let eq = ops.eq {
                let comparand = resolveComparand(eq, context: context)
                result = result && isEqual(sourceValue, comparand)
            }
            if let neq = ops.neq {
                let comparand = resolveComparand(neq, context: context)
                result = result && !isEqual(sourceValue, comparand)
            }
            if let gt = ops.gt {
                let comparand = resolveComparand(gt, context: context)
                result = result && compareNumeric(sourceValue, comparand, op: >)
            }
            if let gte = ops.gte {
                let comparand = resolveComparand(gte, context: context)
                result = result && compareNumeric(sourceValue, comparand, op: >=)
            }
            if let lt = ops.lt {
                let comparand = resolveComparand(lt, context: context)
                result = result && compareNumeric(sourceValue, comparand, op: <)
            }
            if let lte = ops.lte {
                let comparand = resolveComparand(lte, context: context)
                result = result && compareNumeric(sourceValue, comparand, op: <=)
            }
        } else {
            // No operators — truthiness check
            result = sourceValue?.isTruthy ?? false
        }

        // Apply negation
        if ops.not == true {
            result = !result
        }

        return result
    }

    private static func resolveComparand(_ comparand: ConditionComparand, context: ResolutionContext) -> JSONValue? {
        switch comparand {
        case .value(let v): return v
        case .stateRef(let path): return JSONPointer(path).resolve(in: context.state)
        }
    }

    private static func isEqual(_ a: JSONValue?, _ b: JSONValue?) -> Bool {
        switch (a, b) {
        case (.none, .none): return true
        case (.none, _), (_, .none): return false
        case (.some(let a), .some(let b)): return a == b
        }
    }

    private static func compareNumeric(_ a: JSONValue?, _ b: JSONValue?, op: (Double, Double) -> Bool) -> Bool {
        guard let aNum = a?.numericValue, let bNum = b?.numericValue else { return false }
        return op(aNum, bNum)
    }
}
