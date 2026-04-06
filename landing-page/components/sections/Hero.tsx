export function Hero() {
  return (
    <section className="section pb-8">
      <div className="container">
        <div className="mx-auto max-w-4xl text-center">
          <h1 className="text-[clamp(3rem,8vw,5.5rem)] font-semibold tracking-[-0.05em] text-zinc-950">
            Stop Wasting Fuel.
            <br />
            Auto-Optimize Every Route.
          </h1>
          <p className="mx-auto mt-6 max-w-3xl text-lg leading-8 text-zinc-600 sm:text-xl">
            The geofencing and routing platform built for rugged field teams,
            from landscaping crews to snow removal operators.
          </p>
          <div className="mt-8 flex items-center justify-center gap-4">
            <a
              href="#waitlist"
              className="inline-flex rounded-xl bg-[#d90d0d] px-6 py-3 text-sm font-semibold text-white transition hover:bg-[#b70b0b]"
            >
              Join the waitlist
            </a>
          </div>
        </div>

        <div className="surface-card relative mt-12 overflow-hidden rounded-[22px]">
          <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(0,0,0,0.18),transparent_48%,rgba(255,255,255,0.08))]" />
          <div className="grid min-h-[420px] place-items-end bg-[linear-gradient(180deg,#9da7ab_0%,#7f8c90_32%,#59656c_100%)] p-6 sm:p-10">
            <div className="w-full rounded-[20px] border border-white/30 bg-white/10 p-4 backdrop-blur-sm sm:max-w-[48%]">
              <div className="rounded-[16px] border border-white/20 bg-black/15 p-5 text-left text-white">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-white/80">
                  Daily Route Summary
                </p>
                <p className="mt-3 text-2xl font-semibold">14% less drive time</p>
                <p className="mt-2 text-sm leading-6 text-white/80">
                  Smarter sequencing, less windshield time, and better crew
                  accountability without manual route juggling.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
