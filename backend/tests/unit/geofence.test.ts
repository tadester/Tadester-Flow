jest.mock("../../src/services/supabaseService", () => ({
  supabaseAdmin: {},
}));

import {
  calculateDistanceMeters,
  determineGeofenceState,
} from "../../src/services/GeofenceService";

const EARTH_RADIUS_METERS = 6_371_000;

function latitudeOffsetDegrees(distanceMeters: number): number {
  return (distanceMeters / EARTH_RADIUS_METERS) * (180 / Math.PI);
}

describe("geofence point-in-radius logic", () => {
  const origin = { lat: 53.5461, lng: -113.4938 };

  it("should treat a coordinate exactly on the geofence boundary as inside", () => {
    const radiusMeters = 100;
    const boundaryPoint = {
      lat: origin.lat + latitudeOffsetDegrees(radiusMeters),
      lng: origin.lng,
    };

    const measuredDistance = calculateDistanceMeters(
      origin.lat,
      origin.lng,
      boundaryPoint.lat,
      boundaryPoint.lng,
    );

    expect(measuredDistance).toBeCloseTo(radiusMeters, 8);
    expect(determineGeofenceState(measuredDistance, radiusMeters)).toBe("inside");
  });

  it("should mark a coordinate clearly inside the radius as inside", () => {
    const radiusMeters = 100;
    const insidePoint = {
      lat: origin.lat + latitudeOffsetDegrees(35),
      lng: origin.lng,
    };

    const measuredDistance = calculateDistanceMeters(
      origin.lat,
      origin.lng,
      insidePoint.lat,
      insidePoint.lng,
    );

    expect(measuredDistance).toBeLessThan(radiusMeters);
    expect(determineGeofenceState(measuredDistance, radiusMeters)).toBe("inside");
  });

  it("should mark a coordinate clearly outside the radius as outside", () => {
    const radiusMeters = 100;
    const outsidePoint = {
      lat: origin.lat + latitudeOffsetDegrees(180),
      lng: origin.lng,
    };

    const measuredDistance = calculateDistanceMeters(
      origin.lat,
      origin.lng,
      outsidePoint.lat,
      outsidePoint.lng,
    );

    expect(measuredDistance).toBeGreaterThan(radiusMeters);
    expect(determineGeofenceState(measuredDistance, radiusMeters)).toBe("outside");
  });

  it("should stay deterministic under low-accuracy jitter close to the boundary", () => {
    const radiusMeters = 100;
    const jitterOffsets = [-50, -20, 0, 20, 50];

    const evaluations = jitterOffsets.map((jitterMeters) => {
      const point = {
        lat: origin.lat + latitudeOffsetDegrees(radiusMeters + jitterMeters),
        lng: origin.lng,
      };
      const distance = calculateDistanceMeters(
        origin.lat,
        origin.lng,
        point.lat,
        point.lng,
      );

      return {
        jitterMeters,
        distance,
        state: determineGeofenceState(distance, radiusMeters),
      };
    });

    expect(evaluations).toEqual([
      expect.objectContaining({ jitterMeters: -50, state: "inside" }),
      expect.objectContaining({ jitterMeters: -20, state: "inside" }),
      expect.objectContaining({ jitterMeters: 0, state: "inside" }),
      expect.objectContaining({ jitterMeters: 20, state: "outside" }),
      expect.objectContaining({ jitterMeters: 50, state: "outside" }),
    ]);
  });

  it("should produce stable repeated distance calculations for the same points", () => {
    const target = {
      lat: origin.lat + latitudeOffsetDegrees(72),
      lng: origin.lng,
    };

    const readings = Array.from({ length: 5 }, () =>
      calculateDistanceMeters(origin.lat, origin.lng, target.lat, target.lng),
    );

    readings.forEach((reading) => {
      expect(reading).toBeCloseTo(readings[0] as number, 12);
    });
  });
});
