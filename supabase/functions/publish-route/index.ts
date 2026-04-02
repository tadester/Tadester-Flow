import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const body = await req.json();

  try {
    const createdRoutes: Array<{ routeId: string; workerId: string; stopCount: number }> = [];

    for (const route of body.routes) {
      const { data: routeRow, error: routeErr } = await supabase
        .from("routes")
        .insert({
          route_date: body.routeDate,
          worker_id: route.workerId,
          status: "published",
          optimization_provider: "mapbox",
          optimization_payload: route,
          total_distance_m: route.totalDistanceM,
          total_duration_sec: route.totalDurationSec,
        })
        .select("id")
        .single();

      if (routeErr) throw routeErr;

      for (const stop of route.stops) {
        const { data: stopRow, error: stopErr } = await supabase
          .from("route_stops")
          .insert({
            route_id: routeRow.id,
            job_id: stop.jobId,
            stop_order: stop.order,
            planned_arrival: stop.arrival,
            planned_departure: stop.departure,
            stop_status: "planned",
          })
          .select("id")
          .single();

        if (stopErr) throw stopErr;

        const { error: jobErr } = await supabase
          .from("jobs")
          .update({
            assigned_worker_id: route.workerId,
            route_stop_id: stopRow.id,
            status: "assigned",
          })
          .eq("id", stop.jobId);

        if (jobErr) throw jobErr;
      }

      createdRoutes.push({
        routeId: routeRow.id,
        workerId: route.workerId,
        stopCount: route.stops.length,
      });
    }

    return new Response(JSON.stringify({ success: true, createdRoutes }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});