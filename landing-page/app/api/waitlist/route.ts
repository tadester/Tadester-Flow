import { NextResponse } from "next/server";

export async function POST() {
  return NextResponse.json(
    { message: "Waitlist endpoint scaffolded for Phase 1." },
    { status: 501 },
  );
}
