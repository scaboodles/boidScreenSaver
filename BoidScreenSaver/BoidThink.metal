//
//  BoidThink.metal
//  BoidScreenSaver
//
//  Created by Owen Wolff on 8/26/24.
//

#include <metal_stdlib>
using namespace metal;

struct Boid {
	float2 position;
	float2 direction;
	
	float2 flockHeading;
	float2 flockCenter;
	float2 separationHeading;
	uint numFlockmates;
};

// Define the number of threads per threadgroup (workgroup)
//constant uint threadGroupSize = 1024;

kernel void CSMain(
	device Boid* boids [[buffer(0)]],
	constant uint& numBoids [[buffer(1)]],
	constant float& viewRadius [[buffer(2)]],
	constant float& avoidRadius [[buffer(3)]],
	uint id [[thread_position_in_grid]]) {

	if (id >= numBoids) return;

	Boid myBoid = boids[id];

	for (uint indexB = 0; indexB < numBoids; indexB++) {
		if (id != indexB) {
			Boid boidB = boids[indexB];
			float2 offset = boidB.position - myBoid.position;
			float sqrDst = dot(offset, offset);

			if (sqrDst < viewRadius * viewRadius) {
				myBoid.numFlockmates += 1;
				myBoid.flockHeading += boidB.direction;
				myBoid.flockCenter += boidB.position;

				if (sqrDst < avoidRadius * avoidRadius) {
					myBoid.separationHeading -= offset / sqrDst;
				}
			}
		}
	}

	// Write the updated boid data back to the buffer
	boids[id] = myBoid;
}
