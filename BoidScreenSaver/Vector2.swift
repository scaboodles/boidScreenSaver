import Foundation

struct Vector2 {
	var x: CGFloat
	var y: CGFloat

	// Initializer
	init(x: CGFloat, y: CGFloat) {
		self.x = x
		self.y = y
	}

	// Addition
	static func +(left: Vector2, right: Vector2) -> Vector2 {
		return Vector2(x: left.x + right.x, y: left.y + right.y)
	}

	// Subtraction
	static func -(left: Vector2, right: Vector2) -> Vector2 {
		return Vector2(x: left.x - right.x, y: left.y - right.y)
	}

	// Scalar Multiplication
	static func *(vector: Vector2, scalar: CGFloat) -> Vector2 {
		return Vector2(x: vector.x * scalar, y: vector.y * scalar)
	}

	static func /(vector: Vector2, scalar: CGFloat) -> Vector2 {
		guard scalar != 0 else {
			fatalError("Division by zero is not allowed.")
		}
		return Vector2(x: vector.x / scalar, y: vector.y / scalar)
	}

	// Magnitude (Length)
	func magnitude() -> CGFloat {
		return sqrt(x * x + y * y)
	}

	// Normalization
	func normalized() -> Vector2 {
		let length = magnitude()
		return length > 0 ? self * (1 / length) : self
	}
	
	func clampMagnitude(to maxLength: CGFloat) -> Vector2 {
		let length = magnitude()
		if length > maxLength {
			return self.normalized() * maxLength
		} else {
			return self
		}
	}

	// Dot Product
	static func dot(_ left: Vector2, _ right: Vector2) -> CGFloat {
		return left.x * right.x + left.y * right.y
	}

	// Distance between two vectors
	static func distance(_ from: Vector2, _ to: Vector2) -> CGFloat {
		return (to - from).magnitude()
	}

	public func hasNaN() -> Bool{
		return self.x.isNaN || self.y.isNaN
	}
}
