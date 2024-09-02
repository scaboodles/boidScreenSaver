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

	public static let maxSpeed : CGFloat = 80
	public static let minSpeed : CGFloat = 40

	var avoidRadius: CGFloat = 5
	var viewRadius: CGFloat = 10

	public var rotationSpeed : CGFloat = 30
	public var cohesionBias : CGFloat = 10
	public var separationBias : CGFloat = 15
	public var alignmentBias : CGFloat = 10
	public var obstacleAvoidBias : CGFloat = 50

	var boundaryRepulsionDistance : CGFloat = 10.0

	init(position: CGPoint, velocity: Vector2, scaleFactor : CGFloat, id : Int){
		self.pos = position
		self.velocity = velocity
		self.radius = scaleFactor

		self.avgFlockHeading = Vector2(x: 0, y: 0)
		self.avgAvoidanceHeading = Vector2(x: 0, y: 0)
		self.centerOfFlockmates = Vector2(x: 0, y: 0)
		self.numPerceivedFlockmates = 0
		
		boundaryRepulsionDistance = 10 * scaleFactor
		self.id = id
	}

	private func randomBias() -> CGFloat {
		return CGFloat.random(in: 5...20)
	}

	private func randomRadius() -> CGFloat {
		return CGFloat.random(in: 5...10)
	}

	public func mixUp(){
		cohesionBias = randomBias()
		separationBias = randomBias()
		alignmentBias = randomBias()

		avoidRadius = randomRadius()
		viewRadius = randomRadius()
		
		rotationSpeed = randomBias()
		obstacleAvoidBias = CGFloat.random(in: 25...100)
		boundaryRepulsionDistance = CGFloat.random(in: 5...20) * radius
	}
	
	static func == (lhs: Boid, rhs: Boid) -> Bool {
		return lhs.id == rhs.id
	}


	func update(bounds: CGRect, deltaTime: CFTimeInterval){
		var accl : Vector2 = Vector2(x : 0, y : 0)
		if(numPerceivedFlockmates > 0){
			let floatNum = CGFloat(numPerceivedFlockmates)
			centerOfFlockmates = centerOfFlockmates / floatNum
			
			let centerOffset : Vector2 = Vector2(x : centerOfFlockmates.x - pos.x, y : centerOfFlockmates.y - pos.y)

			let alignmentForce = steer(vec: avgFlockHeading) * alignmentBias
			let cohesionForce = steer(vec: centerOffset) * cohesionBias
			let separationForce = steer(vec: avgAvoidanceHeading) * separationBias

			accl = accl + alignmentForce
			accl = accl + cohesionForce
			accl = accl + separationForce
		}


		if(self.pos.x - self.radius <= bounds.minX){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 1, y: 0)) * 150
			accl = accl + avoidForce
		} else if (self.pos.x + self.radius >= bounds.maxX) {
			let avoidForce : Vector2 = steer(vec: Vector2(x: -1, y: 0)) * 150
			accl = accl + avoidForce
		}else{
			if(self.pos.x - self.radius <= bounds.minX + boundaryRepulsionDistance){
				let dist = boundaryRepulsionDistance - (self.pos.x - bounds.minX)
				if(dist > 0){
					let repulse = obstacleAvoidBias * (1 - (dist / boundaryRepulsionDistance))
					let avoidForce : Vector2 = steer(vec: Vector2(x: 1, y: 0)) * repulse
					accl = accl + avoidForce
				}
			} else if (self.pos.x + self.radius >= bounds.maxX - boundaryRepulsionDistance) {
				let dist = boundaryRepulsionDistance - (bounds.maxX - self.pos.x)
				if(dist > 0){
					let repulse = obstacleAvoidBias * (1 - (dist / boundaryRepulsionDistance))
					let avoidForce : Vector2 = steer(vec: Vector2(x: -1, y: 0)) * repulse
					accl = accl + avoidForce
				}
			}
		}

		if(self.pos.y - self.radius <= bounds.minY){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: 1)) * 150
			accl = accl + avoidForce
		} else if(self.pos.y + self.radius >= bounds.maxY){
			let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: -1)) * 150
			accl = accl + avoidForce
		} else{
			if(self.pos.y - self.radius <= bounds.minY + boundaryRepulsionDistance){
				let dist = boundaryRepulsionDistance - (self.pos.y - bounds.minY)
				if(dist > 0){
					let repulse = obstacleAvoidBias * (1 - (dist / boundaryRepulsionDistance))
					let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: 1)) * repulse
					accl = accl + avoidForce
				}
			} else if (self.pos.y + self.radius >= bounds.maxY - boundaryRepulsionDistance) {
				let dist = boundaryRepulsionDistance - (bounds.maxY - self.pos.y)
				if(dist > 0){
					let repulse = obstacleAvoidBias * (1 - (dist / boundaryRepulsionDistance))
					let avoidForce : Vector2 = steer(vec: Vector2(x: 0, y: -1)) * repulse
					accl = accl + avoidForce
				}
			}
		}
		
		if(accl.hasNaN()){
			print("nan accl")
			print(boundaryRepulsionDistance)
			print(obstacleAvoidBias)
		}

		velocity = velocity + (accl * deltaTime)

		if(velocity.hasNaN()){
			print("nan velocity after accl * time")
			print("set vel:")
			print(accl * deltaTime)
			print("accl: ")
			print(accl)
		}else{
			velocity.x += CGFloat.random(in: 0...abs(velocity.x/5)) - abs(velocity.x / 10)
			velocity.y += CGFloat.random(in: 0...abs(velocity.y/5)) - abs(velocity.y / 10)
		}

		var speed = velocity.magnitude()
		let direction : Vector2 = velocity / speed
		speed = min(max(speed, Boid.minSpeed), Boid.maxSpeed)
		velocity = direction * speed

		if(velocity.hasNaN()){
			print("nan velocity after dir * speed")

			let randomD = {() -> CGFloat in
				return CGFloat( arc4random_uniform( UInt32( Boid.maxSpeed - (Boid.maxSpeed / 2) )))
			}

			velocity = Vector2(x: randomD(), y: randomD())
		}

		self.pos.x += velocity.x * deltaTime
		self.pos.y += velocity.y * deltaTime
	}

	private func steer(vec : Vector2) -> Vector2{
		let v : Vector2 = vec.normalized() * Boid.maxSpeed - velocity
		return v.clampMagnitude(to: rotationSpeed)
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
