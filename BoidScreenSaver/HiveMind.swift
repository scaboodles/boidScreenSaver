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

    var avoidRadius: Float = 10
    var viewRadius: Float = 20

    init(frame : NSRect){
        self.scaleFactor = sqrt( ((frame.width * frame.height) / 4096) / .pi)
        self.frame = frame
    }

    func populateBoids(numBoids: Int){
        for _ in 0...numBoids {
            boids.append(initRandomBoid(frame: frame, scaleFac : scaleFactor))
        }
    }

	public struct BoidStructGPU {
		var position: SIMD2<Float>
		var direction: SIMD2<Float>
		var flockHeading: SIMD2<Float>
		var flockCenter: SIMD2<Float>
		var separationHeading: SIMD2<Float>
		var numFlockmates: UInt32
	}

    private func initBoidBuffer(device : MTLDevice) -> MTLBuffer {
        var gpuBoids = [BoidStructGPU]()
        for boid in boids{
            let gpuBoid = BoidStructGPU(
                position: SIMD2<Float>(Float(boid.pos.x), Float(boid.pos.y)),
                direction: SIMD2<Float>(Float(boid.velocity.x), Float(boid.velocity.y)),
                flockHeading: SIMD2<Float>(0,0),
                flockCenter: SIMD2<Float>(0,0),
                separationHeading: SIMD2<Float>(0,0),
                numFlockmates: UInt32(0)
            )
            gpuBoids.append(gpuBoid)
        }

        let numBoids = boids.count
        let boidBuffer = device.makeBuffer(bytes: gpuBoids, length: MemoryLayout<BoidStructGPU>.stride * numBoids, options: [])
		return boidBuffer!
    }

    func flock(metalManager: MetalManager){
        let numBoids : Int = (boids.count)
		let boidBuffer = initBoidBuffer(device: metalManager.getDevice())
        metalManager.performBoidSimulation(boidBuffer : boidBuffer,
										   numBoids: UInt32(numBoids), 
                                           viewRadius: viewRadius, 
                                           avoidRadius: avoidRadius, 
                                           boidStructStride: MemoryLayout<BoidStructGPU>.stride)
        
		let updatedBoids : [BoidStructGPU] = MetalManager.getUpdatedBoids(from: boidBuffer, numBoids: numBoids)
        for (i, boidStruct) in updatedBoids.enumerated(){
            boids[i].getDataFromShader(gpuBoid: boidStruct)
        }
    }

    func drawBoids(){
        for boid in boids {
            boid.draw()
        }        
    }

    func updateBoids(bounds : NSRect, metalManager : MetalManager, deltaTime : CFTimeInterval){
        flock(metalManager : metalManager)
        for boid in boids {
            boid.update(bounds: bounds, deltaTime: deltaTime)
        }        
    }

    private func randomCGFLoat(bound: UInt32) -> CGFloat {
        return CGFloat(arc4random_uniform(bound))
    }

    private func initRandomBoid(frame : NSRect, scaleFac : CGFloat) -> Boid {
        let randomPos = CGPoint(x: randomCGFLoat(bound : UInt32(frame.width)), y: randomCGFLoat(bound : UInt32(frame.height)))

        let randomD = {() -> CGFloat in
            return self.randomCGFLoat(bound: UInt32(Boid.maxSpeed)) - CGFloat(Boid.maxSpeed / 2)
        }

        let randomVelocity = Vector2(x: randomD(), y: randomD())

        let newBoid = Boid(position: randomPos, velocity: randomVelocity, scaleFactor: scaleFac)

        return newBoid
    }
}
