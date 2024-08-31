import Cocoa

class Boid {
	var pos : CGPoint
	var velocity : Vector2
	var radius : CGFloat 

    var avgFlockHeading : Vector2; // received from hivemind
    var avgAvoidanceHeading : Vector2 // received from hivemind
    var centerOfFlockmates : Vector2 // received from hivemind
    var numPerceivedFlockmates : Int // received from hivemindCompute	

	public static let maxSpeed : CGFloat = 6
	public static let minSpeed : CGFloat = 3

	public static let rotationSpeed : CGFloat = 4
	public static let cohesionBias : CGFloat = 2
	public static let separationBias : CGFloat = 2
	public static let alignmentBias : CGFloat = 2

	init(position: CGPoint, velocity: Vector2, scaleFactor : CGFloat){
		self.pos = position
		self.velocity = velocity
		self.radius = scaleFactor

		self.avgFlockHeading = Vector2(x: 0, y: 0)
		self.avgAvoidanceHeading = Vector2(x: 0, y: 0)
		self.centerOfFlockmates = Vector2(x: 0, y: 0)
		self.numPerceivedFlockmates = 0
	}

	func update(bounds: CGRect, deltaTime: CFTimeInterval){
		//if self.pos.x - self.radius < bounds.minX || self.pos.x + self.radius > bounds.maxX {
			//velocity.dx = -velocity.dx
		//}
		//if self.pos.y - self.radius < bounds.minY || self.pos.y + self.radius > bounds.maxY {
			//velocity.dy = -velocity.dy
		//}

		//self.pos.x += velocity.dx
		//self.pos.y += velocity.dy

		var accl : Vector2 = Vector2(x : 0, y : 0)
		if(numPerceivedFlockmates > 0){
			let floatNum = CGFloat(numPerceivedFlockmates)
			centerOfFlockmates = centerOfFlockmates / floatNum
			
			let centerOffset : Vector2 = Vector2(x : centerOfFlockmates.x - pos.x, y : centerOfFlockmates.y - pos.y)

			let alignmentForce = steer(vec: avgFlockHeading) * Boid.alignmentBias
			let cohesionForce = steer(vec: centerOffset) * Boid.cohesionBias
			let separationForce = steer(vec: avgAvoidanceHeading) * Boid.separationBias

			accl = accl + alignmentForce
            accl = accl + cohesionForce
            accl = accl + separationForce
		}
		
		// check collision here

		velocity = velocity + (accl * deltaTime)
		var speed = velocity.magnitude()
		let direction : Vector2 = velocity / speed
		speed = min(max(speed, Boid.minSpeed), Boid.maxSpeed)
		velocity = direction * speed

		self.pos.x += velocity.x * deltaTime
		self.pos.y += velocity.y * deltaTime
	}

	private func steer(vec : Vector2) -> Vector2{
		let v : Vector2 = vec.normalized() * Boid.maxSpeed - velocity
		return v.clampMagnitude(to: Boid.rotationSpeed)
	}

	func draw() {
		let path = NSBezierPath(ovalIn: CGRect(x: self.pos.x - self.radius, y: self.pos.y - self.radius, width: self.radius * 2, height: self.radius * 2))
		NSColor.white.setFill()
		path.fill()
	}


	//public struct BoidStructGPU {
		//var position: SIMD2<Float>
		//var direction: SIMD2<Float>
		//var flockHeading: SIMD2<Float>
		//var flockCenter: SIMD2<Float>
		//var separationHeading: SIMD2<Float>
		//var numFlockmates: UInt32
	//}

	func simd2ToVector(simd: SIMD2<Float>) -> Vector2{
		return Vector2(x: CGFloat(simd.x), y: CGFloat(simd.y))
	}
	func getDataFromShader(gpuBoid : HiveMind.BoidStructGPU){
		self.avgFlockHeading = simd2ToVector(simd : gpuBoid.flockHeading)
		self.avgAvoidanceHeading = simd2ToVector(simd: gpuBoid.separationHeading)
		self.centerOfFlockmates = simd2ToVector(simd: gpuBoid.flockCenter)
		self.numPerceivedFlockmates = Int(gpuBoid.numFlockmates)
	}

}
