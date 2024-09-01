//
//  HiveMind.swift
//  BoidScreenSaver
//
//  Created by Owen Wolff on 8/27/24.
//

import Foundation
import Metal

class HiveMind{
    public var boids: [Boid] = []
    var scaleFactor: CGFloat
    var frame: NSRect

    var avoidRadius: CGFloat = 10
    var viewRadius: CGFloat = 20

    init(frame : NSRect){
        self.scaleFactor = sqrt( ((frame.width * frame.height) / 4096) / .pi)
        self.frame = frame
    }

    func populateBoids(numBoids: Int){
        for i in 0...numBoids {
			boids.append(initRandomBoid(frame: frame, scaleFac : scaleFactor, id:i))
        }
    }

    func flock(){
        let scaleFactor = boids[0].radius
        for boid in boids{
            boid.reset()
            for otherBoid in boids{
                if(boid != otherBoid){
					let offset:Vector2 = Vector2(x: otherBoid.pos.x - boid.pos.x, y: otherBoid.pos.y - boid.pos.y)
					let sqrDist: CGFloat = Vector2.dot(offset, offset)

                    let scaledViewRadius = viewRadius * scaleFactor
                    if(sqrDist < scaledViewRadius * scaledViewRadius){
                        boid.numPerceivedFlockmates += 1
						boid.avgFlockHeading = Vector2(x :boid.avgFlockHeading.x + otherBoid.pos.x, y: boid.avgFlockHeading.y + otherBoid.pos.y)
						boid.centerOfFlockmates = Vector2(x: boid.centerOfFlockmates.x + otherBoid.pos.x, y: boid.centerOfFlockmates.y + otherBoid.pos.y)
                    
                        let scaledAvoidRadius = avoidRadius * scaleFactor
                        if(sqrDist < scaledAvoidRadius * scaledAvoidRadius){
                            boid.avgAvoidanceHeading = boid.avgAvoidanceHeading - (offset / sqrDist)
                        }
                    }
                }
            }
        }
    }

    func drawBoids(){
        for boid in boids {
            boid.draw()
        }        
    }

    func updateBoids(bounds : NSRect, deltaTime : CFTimeInterval){
        flock()
        for boid in boids {
            boid.update(bounds: bounds, deltaTime: deltaTime)
        }        
    }

    private func randomCGFLoat(bound: UInt32) -> CGFloat {
        return CGFloat(arc4random_uniform(bound))
    }

	private func initRandomBoid(frame : NSRect, scaleFac : CGFloat, id: Int) -> Boid {
        let randomPos = CGPoint(x: randomCGFLoat(bound : UInt32(frame.width)), y: randomCGFLoat(bound : UInt32(frame.height)))

        let randomD = {() -> CGFloat in
            return self.randomCGFLoat(bound: UInt32(Boid.maxSpeed)) - CGFloat(Boid.maxSpeed / 2)
        }

        let randomVelocity = Vector2(x: randomD(), y: randomD())

		let newBoid = Boid(position: randomPos, velocity: randomVelocity, scaleFactor: scaleFac, id : id)

        return newBoid
    }
}