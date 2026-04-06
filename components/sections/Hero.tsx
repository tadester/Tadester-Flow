import Image from "next/image";

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
          <div className="absolute inset-0">
            <Image
              src="/images/hero-field-operations.jpg"
              alt="Field operations vehicle working in winter conditions"
              fill
              priority
              className="object-cover"
              sizes="(max-width: 768px) 100vw, 1120px"
            />
          </div>
          <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(14,18,24,0.1),rgba(14,18,24,0.3)_44%,rgba(14,18,24,0.64)_100%)]" />
          <div className="relative grid min-h-[420px] place-items-end p-6 sm:p-10">
            <div className="w-full rounded-[20px] border border-white/18 bg-[rgba(12,18,30,0.58)] p-4 backdrop-blur-xl sm:max-w-[52%]">
              <div className="rounded-[16px] border border-white/14 bg-[rgba(20,28,42,0.42)] p-5 text-left text-white shadow-[0_18px_34px_rgba(0,0,0,0.28)]">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-white/90">
                  Daily Route Summary
                </p>
                <p className="mt-3 text-2xl font-semibold text-white sm:text-[1.75rem]">
                  14% less drive time
                </p>
                <p className="mt-2 text-base leading-7 text-white/92">
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
