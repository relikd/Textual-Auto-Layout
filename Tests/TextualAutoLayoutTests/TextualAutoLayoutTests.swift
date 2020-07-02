import XCTest
@testable import TextualAutoLayout

final class TextualAutoLayoutTests: XCTestCase {
	var parent, A, B: ConstraintView!
	
	override func setUp() {
		parent = ConstraintView()
		A = ConstraintView()
		B = ConstraintView()
		parent.addSubview(A)
		parent.addSubview(B)
	}
	
    func testBasic() {
		let x = A.bottomAnchor =&= B.topAnchor + 20.3 | .defaultLow
		XCTAssertEqual(x.relation, NSLayoutConstraint.Relation.equal)
		XCTAssertEqual(x.priority, ConstraintPriority.defaultLow)
		XCTAssertEqual(x.constant, 20.3)
		XCTAssertEqual(x.isActive, true)
    }
	
	func testDimensional() {
		let x = A.heightAnchor =<= 2 * B.widthAnchor - 4
		XCTAssertEqual(x.relation, NSLayoutConstraint.Relation.lessThanOrEqual)
		XCTAssertEqual(x.priority, ConstraintPriority.required)
		XCTAssertEqual(x.multiplier, 2)
		XCTAssertEqual(x.constant, -4)
		XCTAssertEqual(x.isActive, true)
		
		XCTAssertEqual((A.widthAnchor =>= 2 * A.heightAnchor).constant, 0)
		XCTAssertEqual((A.widthAnchor =<= 250).constant, 250)
	}
	
	func testIntrinsicContent() {
		A.constrainHuggingCompression(.vertical, .required)
		// newly set values
		XCTAssertEqual(A.contentCompressionResistancePriority(for: .vertical), ConstraintPriority.required)
		XCTAssertEqual(A.contentHuggingPriority(for: .vertical), ConstraintPriority.required)
		// default values
		XCTAssertEqual(A.contentCompressionResistancePriority(for: .horizontal), ConstraintPriority.defaultHigh)
		XCTAssertEqual(A.contentHuggingPriority(for: .horizontal), ConstraintPriority.defaultLow)
	}
	
	func testReturnConstraint() {
		XCTAssertEqual((A.rightAnchor =&= B.leftAnchor).firstItem as? ConstraintView, A)
	}
	
	func testViewMultiConstraint() {
		A.anchor([.left, .right, .top], to: parent!, padding: 76) | .defaultHigh
		let x = parent.constraints
		XCTAssertEqual(x.count, 3)
		XCTAssertEqual(A.translatesAutoresizingMaskIntoConstraints, false)
		XCTAssertEqual(parent.translatesAutoresizingMaskIntoConstraints, true)
		
		for u in x {
			XCTAssertEqual(u.relation, NSLayoutConstraint.Relation.equal)
			XCTAssertEqual(u.priority, ConstraintPriority.defaultHigh)
			XCTAssertEqual(u.constant, 76)
			XCTAssertEqual(u.firstAttribute, u.secondAttribute)
			XCTAssertEqual(u.isActive, true)
			
			let first = u.firstItem as? ConstraintView
			let second = u.secondItem as? ConstraintView
			if u.firstAttribute == .right {
				XCTAssertEqual(first, parent)
				XCTAssertEqual(second, A)
			} else {
				XCTAssertEqual(first, A)
				XCTAssertEqual(second, parent)
			}
		}
		x.setActive(false)
		for u in x { XCTAssertEqual(u.isActive, false) }
	}
}
