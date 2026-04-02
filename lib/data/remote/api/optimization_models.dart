{
  "routeDate": "2026-04-01",
  "profile": "driving",
  "jobs": [
    {
      "id": "job-1",
      "name": "Front Lawn Cut",
      "lat": 53.5461,
      "lng": -113.4938,
      "durationSec": 1800,
      "timeWindowStart": "2026-04-01T08:00:00Z",
      "timeWindowEnd": "2026-04-01T10:00:00Z",
      "requiredSkills": ["mowing"],
      "priority": 2
    }
  ],
  "workers": [
    {
      "id": "worker-1",
      "name": "Crew A",
      "startLat": 53.5400,
      "startLng": -113.5000,
      "endLat": 53.5400,
      "endLng": -113.5000,
      "shiftStart": "2026-04-01T08:00:00Z",
      "shiftEnd": "2026-04-01T16:00:00Z",
      "skills": ["mowing", "trimming"],
      "capacity": 12
    }
  ]
}

{
  "provider": "mapbox",
  "routeDate": "2026-04-01",
  "routes": [
    {
      "workerId": "worker-1",
      "totalDistanceM": 15423,
      "totalDurationSec": 20340,
      "stops": [
        {
          "order": 1,
          "jobId": "job-1",
          "arrival": "2026-04-01T08:22:00Z",
          "departure": "2026-04-01T08:52:00Z",
          "locationName": "job-1"
        }
      ]
    }
  ],
  "unassigned": [],
  "raw": {}
}
{
  "pings": [
    {
      "workerId": "worker-1",
      "routeId": "route-1",
      "recordedAt": "2026-04-01T09:05:00Z",
      "lat": 53.5462,
      "lng": -113.4931,
      "accuracyM": 8.4,
      "speedMps": 2.1,
      "headingDeg": 120.0,
      "batteryPct": 0.62
    }
  ]
}
{
  "success": true,
  "accepted": 1
}
{
  "events": [
    {
      "workerId": "worker-1",
      "jobId": "job-1",
      "routeId": "route-1",
      "eventType": "enter",
      "eventAt": "2026-04-01T09:06:10Z",
      "lat": 53.5462,
      "lng": -113.4931,
      "accuracyM": 8.4,
      "dwellSeconds": 60,
      "metadata": {
        "source": "gps"
      }
    }
  ]
}{
  "success": true,
  "accepted": 1
}