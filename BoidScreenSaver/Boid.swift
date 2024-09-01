import Cocoa

class Boid : Equatable{
	var pos : CGPoint
	var velocity : Vector2
	var radius : CGFloat 

    var avgFlockHeading : Vector2; // received from hivemind
    var avgAvoidanceHeading : Vector2 // received from hivemind
    var centerOfFlockmates : Vector2 // received from hivemind
    var numPerceivedFlockmates : Int // received from hivemindCompute	
	
	var id : Int

	public static let maxSpeed : CGFloat = 40
	public static let minSpeed : CGFloat = 20

	public static let rotationSpeed : CGFloat = 9
	public static let cohesionBias : CGFloat = 5
	public static let separationBias : CGFloat = 15
	public static let alignmentBias : CGFloat = 3
	public static let obstacleAvoidBias : CGFloat = 50

	init(position: CGPoint, velocity: Vector2, scaleFactor : CGFloat, id : Int){
		self.pos = position
		self.velocity = velocity
		self.radius = scaleFactor

		self.avgFlockHeading = Vector2(x: 0, y: 0)
		self.avgAvoidanceHeading = Vector2(x: 0, y: 0)
		self.centerOfFlockmates = Vector2(x: 0, y: 0)
		self.numPerceivedFlockmates = 0
		
		self.id = id
	}
	
	static func == (lhs: Boid, rhs: Boid) -> Bool {
		return lhs.id == rhs.id
	}

	func update(bounds: CGRect, deltaTime: CFTimeInterval){
		let scaleFactor = radius
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
		
		if(self.pos.x - self.radius < bounds.minX){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 1, y: 0)) * Boid.obstacleAvoidBias
			accl = accl + avoidForce
		} else if (self.pos.x + self.radius > bounds.maxX) {
			let avoidForce : Vector2 = steer(vec: Vector2(x: -1, y: 0)) * Boid.obstacleAvoidBias
			accl = accl + avoidForce
		}

		if(self.pos.y - self.radius < bounds.minY){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: 1)) * Boid.obstacleAvoidBias
			accl = accl + avoidForce
		} else if(self.pos.y + self.radius > bounds.maxY){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: -1)) * Boid.obstacleAvoidBias
			accl = accl + avoidForce
		}

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

	func reset(){
		self.avgFlockHeading = Vector2(x: 0, y: 0)
		self.avgAvoidanceHeading = Vector2(x: 0, y: 0)
		self.centerOfFlockmates = Vector2(x: 0, y: 0)
		self.numPerceivedFlockmates = 0
	}
}
