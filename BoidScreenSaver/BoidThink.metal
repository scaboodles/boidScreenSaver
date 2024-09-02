//
//  BoidThink.metal
//  BoidScreenSaver
//
//  Created by Owen Wolff on 9/1/24.
//

#include <metal_stdlib>
using namespace metal;

struct Boid {
	float2 position;
	float2 velocity;
	
	float viewRadius;
	float avoidRadius;
	
	float2 avgFlockHeading;
	float2 centerOfFlockmates;
	float2 avgAvoidanceHeading;
	uint numPerceivedFlockmates;
};

kernel void flockingKernel(device Boid* boids [[buffer(0)]], constant float& scaleFactor [[buffer(1)]], constant uint& numBoids [[buffer(2)]], uint id [[thread_position_in_grid]]) {
	Boid currentBoid = boids[id];

	currentBoid.numPerceivedFlockmates = 0;
	currentBoid.avgFlockHeading = float2(0);
	currentBoid.centerOfFlockmates = float2(0);
	currentBoid.avgAvoidanceHeading = float2(0);

	for (uint i = 0; i < numBoids; ++i) {
		if (i != id) {
			Boid otherBoid = boids[i];
			float2 offset = otherBoid.position - currentBoid.position;
			float sqrDist = dot(offset, offset);

			float scaledViewRadius = currentBoid.viewRadius * scaleFactor;
			if (sqrDist < scaledViewRadius * scaledViewRadius) {
				currentBoid.numPerceivedFlockmates += 1;
				currentBoid.avgFlockHeading += otherBoid.velocity;
				currentBoid.centerOfFlockmates += otherBoid.position;
			}
			
			float scaledAvoidRadius = currentBoid.avoidRadius * scaleFactor;
			if (sqrDist < scaledAvoidRadius * scaledAvoidRadius) {
				currentBoid.avgAvoidanceHeading -= offset / sqrDist;
			}
		}
	}
	
	boids[id] = currentBoid;
}
