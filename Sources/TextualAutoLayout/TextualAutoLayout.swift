#if os(macOS)
import AppKit
public typealias ConstraintPriority = NSLayoutConstraint.Priority
public typealias ConstraintAxis = NSLayoutConstraint.Orientation
public typealias ConstraintView = NSView
#else
import UIKit
public typealias ConstraintPriority = UILayoutPriority
public typealias ConstraintAxis = NSLayoutConstraint.Axis
public typealias ConstraintView = UIView
#endif

/*
  Readable Auto Layout Constraints

  Usage:
    A.anchor =&= multiplier * B.anchor + constant | priority
*/

precedencegroup ReadableLayoutPrecedence {
	higherThan: AdditionPrecedence
	lowerThan: MultiplicationPrecedence
}

infix operator =&= : ReadableLayoutPrecedence
infix operator =<= : ReadableLayoutPrecedence
infix operator =>= : ReadableLayoutPrecedence

/// Create and activate an `equal` constraint between left and right anchor. Format: `A.anchor =&= multiplier * B.anchor + constant | priority`
@discardableResult public func =&= <T>(l: NSLayoutAnchor<T>, r: NSLayoutAnchor<T>) -> NSLayoutConstraint { l.constraint(equalTo: r).on() }
/// Create and activate a `lessThan` constraint between left and right anchor. Format: `A.anchor =<= multiplier * B.anchor + constant | priority`
@discardableResult public func =<= <T>(l: NSLayoutAnchor<T>, r: NSLayoutAnchor<T>) -> NSLayoutConstraint { l.constraint(lessThanOrEqualTo: r).on() }
/// Create and activate a `greaterThan` constraint between left and right anchor. Format: `A.anchor =>= multiplier * B.anchor + constant | priority`
@discardableResult public func =>= <T>(l: NSLayoutAnchor<T>, r: NSLayoutAnchor<T>) -> NSLayoutConstraint { l.constraint(greaterThanOrEqualTo: r).on() }

public extension NSLayoutDimension { // higher precedence, so multiply first
	/// Create intermediate anchor multiplier result.
	static func *(l: CGFloat, r: NSLayoutDimension) -> AnchorMultiplier { .init(anchor: r, m: l) }
	/// Create and activate an `equal` constraint with constant value. Format: `A.anchor =&= constant | priority`
	@discardableResult static func =&=(l: NSLayoutDimension, r: CGFloat) -> NSLayoutConstraint { l.constraint(equalToConstant: r).on() }
	/// Create and activate a `lessThan` constraint with constant value. Format: `A.anchor =<= constant | priority`
	@discardableResult static func =<=(l: NSLayoutDimension, r: CGFloat) -> NSLayoutConstraint { l.constraint(lessThanOrEqualToConstant: r).on() }
	/// Create and activate a `greaterThan` constraint with constant value. Format: `A.anchor =>= constant | priority`
	@discardableResult static func =>=(l: NSLayoutDimension, r: CGFloat) -> NSLayoutConstraint { l.constraint(greaterThanOrEqualToConstant: r).on() }
}

/// Intermediate `NSLayoutConstraint` anchor with multiplier supplement
public struct AnchorMultiplier {
	fileprivate let anchor: NSLayoutDimension, m: CGFloat
}

public extension AnchorMultiplier {
	/// Create and activate an `equal` constraint between left and right anchor. Format: `A.anchor =&= multiplier * B.anchor + constant | priority`
	@discardableResult static func =&=(l: NSLayoutDimension, r: Self) -> NSLayoutConstraint { l.constraint(equalTo: r.anchor, multiplier: r.m).on() }
	/// Create and activate a `lessThan` constraint between left and right anchor. Format: `A.anchor =<= multiplier * B.anchor + constant | priority`
	@discardableResult static func =<=(l: NSLayoutDimension, r: Self) -> NSLayoutConstraint { l.constraint(lessThanOrEqualTo: r.anchor, multiplier: r.m).on() }
	/// Create and activate a `greaterThan` constraint between left and right anchor. Format: `A.anchor =>= multiplier * B.anchor + constant | priority`
	@discardableResult static func =>=(l: NSLayoutDimension, r: Self) -> NSLayoutConstraint { l.constraint(greaterThanOrEqualTo: r.anchor, multiplier: r.m).on() }
}

public extension NSLayoutConstraint {
	/// Change `isActive`to `true` and return `self`
	func on() -> Self { isActive = true; return self }
	/// Change `isActive`to `false` and return `self`
	func off() -> Self { isActive = false; return self }
	/// Change `constant`attribute  and return `self`
	@discardableResult static func +(l: NSLayoutConstraint, r: CGFloat) -> NSLayoutConstraint { l.constant = r; return l }
	/// Change `constant` attribute and return `self`
	@discardableResult static func -(l: NSLayoutConstraint, r: CGFloat) -> NSLayoutConstraint { l.constant = -r; return l }
	/// Change `priority` attribute and return `self`
	@discardableResult static func |(l: NSLayoutConstraint, r: ConstraintPriority) -> NSLayoutConstraint { l.priority = r; return l }
}

/*
  UIView extension to generate multiple constraints at once

  Usage:
    child.anchor([.width, .height], to: parent) | .defaultLow
*/

public extension ConstraintView {
	#if os(macOS)
	/// Edges that need the relation to flip arguments. For these we need to inverse the constant value and relation.
	private static let inverseItem: [NSLayoutConstraint.Attribute] = [.right, .bottom, .trailing, .lastBaseline]
	#else
	/// Edges that need the relation to flip arguments. For these we need to inverse the constant value and relation.
	private static let inverseItem: [NSLayoutConstraint.Attribute] = [.right, .bottom, .trailing, .lastBaseline, .rightMargin, .bottomMargin, .trailingMargin]
	#endif
	
	/// Create and active constraints for provided edges. Constraints will anchor the same edge on both `self` and `other`.
	/// - Note: Will set `translatesAutoresizingMaskIntoConstraints = false`
	/// - Parameters:
	///   - edges: List of constraint attributes, e.g. `[.top, .bottom, .left, .right]`
	///   - other: Instance to bind to, e.g. `UIView` or `UILayoutGuide`
	///   - padding: Used as constant value. Multiplier will always be `1.0`. If you need to change the multiplier, use single constraints instead. (Default: `0`)
	///   - rel: Constraint relation. (Default: `.equal`)
	/// - Returns: List of created and active constraints
	@discardableResult func anchor(_ edges: [NSLayoutConstraint.Attribute], to other: Any, padding: CGFloat = 0, if rel: NSLayoutConstraint.Relation = .equal) -> [NSLayoutConstraint] {
		translatesAutoresizingMaskIntoConstraints = false
		return edges.map {
			let (A, B) = Self.inverseItem.contains($0) ? (other, self) : (self, other)
			return NSLayoutConstraint(item: A, attribute: $0, relatedBy: rel, toItem: B, attribute: $0, multiplier: 1, constant: padding).on()
		}
	}
	
	/// Sets the priority with which a view resists being made smaller and larger than its intrinsic size.
	func constrainHuggingCompression(_ axis: ConstraintAxis, _ priotity: ConstraintPriority) {
		setContentHuggingPriority(priotity, for: axis)
		setContentCompressionResistancePriority(priotity, for: axis)
	}
}

public extension Array where Element: NSLayoutConstraint {
	/// set `priority` on all elements and return same list
	@discardableResult static func |(l: Self, r: ConstraintPriority) -> Self {
		for x in l { x.priority = r }
		return l
	}
	/// set `isActive` on all elements and return `self`
	@discardableResult func setActive(_ flag: Bool) -> Self {
		flag ? NSLayoutConstraint.activate(self) : NSLayoutConstraint.deactivate(self)
		return self
	}
}

// I couldn't find a better way to handle it, but these methods are particularly useful.
// Sadly, the syntax isn't quite as readable as the stuff above.

#if !os(macOS)
@available(iOS 11, tvOS 11, *)
public extension NSLayoutXAxisAnchor {
	/// Calls and activates `.constraint(equalToSystemSpacingAfter: a)`
	@discardableResult func systemSpacing(_ equal: NSLayoutXAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(equalToSystemSpacingAfter: equal, multiplier: m).on() }
	/// Calls and activates `.constraint(lessThanOrEqualToSystemSpacingAfter: a)`
	@discardableResult func systemSpacing(lessThan a: NSLayoutXAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(lessThanOrEqualToSystemSpacingAfter: a, multiplier: m).on() }
	/// Calls and activates `.constraint(greaterThanOrEqualToSystemSpacingAfter: a)`
	@discardableResult func systemSpacing(greaterThan a: NSLayoutXAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(greaterThanOrEqualToSystemSpacingAfter: a, multiplier: m).on() }
}
@available(iOS 11, tvOS 11, *)
public extension NSLayoutYAxisAnchor {
	/// Calls and activates `.constraint(equalToSystemSpacingBelow: a)`
	@discardableResult func systemSpacing(_ equal: NSLayoutYAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(equalToSystemSpacingBelow: equal, multiplier: m).on() }
	/// Calls and activates `.constraint(lessThanOrEqualToSystemSpacingBelow: a)`
	@discardableResult func systemSpacing(lessThan a: NSLayoutYAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(lessThanOrEqualToSystemSpacingBelow: a, multiplier: m).on() }
	/// Calls and activates `.constraint(greaterThanOrEqualToSystemSpacingBelow: a)`
	@discardableResult func systemSpacing(greaterThan a: NSLayoutYAxisAnchor, multiplier m: CGFloat = 1.0) -> NSLayoutConstraint { constraint(greaterThanOrEqualToSystemSpacingBelow: a, multiplier: m).on() }
}
#endif
