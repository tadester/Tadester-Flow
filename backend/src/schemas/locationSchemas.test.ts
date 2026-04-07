import test from "node:test";
import assert from "node:assert/strict";

import { createLocationSchema } from "./locationSchemas";

test("createLocationSchema accepts a valid payload", () => {
  const parsed = createLocationSchema.parse({
    name: "North Yard",
    addressLine1: "123 Main St",
    city: "Edmonton",
    region: "AB",
    postalCode: "T5J 0N3",
    country: "Canada",
    latitude: 53.5461,
    longitude: -113.4938,
    geofenceRadiusMeters: 150,
  });

  assert.equal(parsed.status, "active");
  assert.equal(parsed.name, "North Yard");
});

test("createLocationSchema rejects invalid coordinates", () => {
  assert.throws(
    () =>
      createLocationSchema.parse({
        name: "Bad Yard",
        addressLine1: "123 Main St",
        city: "Edmonton",
        region: "AB",
        postalCode: "T5J 0N3",
        country: "Canada",
        latitude: 120,
        longitude: -113.4938,
        geofenceRadiusMeters: 150,
      }),
    /Number must be less than or equal to 90/,
  );
});
