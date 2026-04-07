jest.mock("../../src/services/supabaseService", () => ({
  supabaseAdmin: {},
}));

import {
  determineTransitionEvent,
  mapEventToState,
  type GeofenceEventType,
  type GeofenceState,
} from "../../src/services/GeofenceService";

function applyStateSequence(
  states: readonly GeofenceState[],
  initialState: GeofenceState | null,
): GeofenceEventType[] {
  let previousState = initialState;
  const emittedEvents: GeofenceEventType[] = [];

  for (const currentState of states) {
    const event = determineTransitionEvent(previousState, currentState);

    if (event) {
      emittedEvents.push(event);
      previousState = mapEventToState(event);
    } else {
      previousState = currentState;
    }
  }

  return emittedEvents;
}

describe("geofence state transition logic", () => {
  it('should emit only one entry event when transitioning from "outside" to "inside"', () => {
    expect(determineTransitionEvent("outside", "inside")).toBe("geofence_enter");
  });

  it('should emit only one exit event when transitioning from "inside" to "outside"', () => {
    expect(determineTransitionEvent("inside", "outside")).toBe("geofence_exit");
  });

  it("should not emit duplicate entry events when already inside", () => {
    expect(determineTransitionEvent("inside", "inside")).toBeNull();
  });

  it("should not emit duplicate exit events when already outside", () => {
    expect(determineTransitionEvent("outside", "outside")).toBeNull();
  });

  it("should not emit an event on the very first observed state", () => {
    expect(determineTransitionEvent(null, "inside")).toBeNull();
    expect(determineTransitionEvent(null, "outside")).toBeNull();
  });

  it("should only emit transitions during rapid noisy toggling", () => {
    const events = applyStateSequence(
      ["outside", "inside", "outside", "inside", "inside", "outside"],
      "outside",
    );

    expect(events).toEqual([
      "geofence_enter",
      "geofence_exit",
      "geofence_enter",
      "geofence_exit",
    ]);
  });

  it("should stay quiet when repeated jitter never changes the resolved state", () => {
    const events = applyStateSequence(
      ["inside", "inside", "inside", "inside"],
      "inside",
    );

    expect(events).toEqual([]);
  });
});
