const features = [
  {
    title: "Automated Accountability",
    description:
      "Geofences automatically clock workers in and out when they arrive at a job.",
    glyph: "pin",
  },
  {
    title: "Smart Routing",
    description:
      "The most efficient stop order, generated in seconds for busy dispatchers.",
    glyph: "route",
  },
  {
    title: "Real-Time Map Visibility",
    description:
      "See each crew's location and job status from a single operational view.",
    glyph: "signal",
  },
];

function FeatureIcon({ glyph }: { glyph: string }) {
  if (glyph === "route") {
    return (
      <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M7 7h10" />
        <path d="M7 17h10" />
        <path d="M7 7a2 2 0 1 0-4 0a2 2 0 0 0 4 0Z" />
        <path d="M21 17a2 2 0 1 1-4 0a2 2 0 0 1 4 0Z" />
        <path d="M19 7a2 2 0 1 0-4 0a2 2 0 0 0 4 0Z" />
        <path d="M9 17a2 2 0 1 1-4 0a2 2 0 0 1 4 0Z" />
      </svg>
    );
  }

  if (glyph === "signal") {
    return (
      <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M12 17v.01" />
        <path d="M8.5 13.5a5 5 0 0 1 7 0" />
        <path d="M5 10a10 10 0 0 1 14 0" />
        <path d="M1.5 6.5a15 15 0 0 1 21 0" />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 24 24" className="h-7 w-7" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 21s-6-4.35-6-10a6 6 0 1 1 12 0c0 5.65-6 10-6 10Z" />
      <circle cx="12" cy="11" r="2.5" />
    </svg>
  );
}

export function Features() {
  return (
    <section className="section bg-[#f2f4f6]">
      <div className="container">
        <div className="grid gap-6 md:grid-cols-3">
          {features.map((feature) => (
            <article
              key={feature.title}
              className="flex flex-col items-center rounded-[22px] bg-white px-6 py-8 text-center shadow-[0_10px_30px_rgba(15,23,42,0.06)]"
            >
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#d90d0d] text-white">
                <FeatureIcon glyph={feature.glyph} />
              </div>
              <h3 className="mt-6 text-2xl font-semibold text-zinc-950">
                {feature.title}
              </h3>
              <p className="mt-3 max-w-xs text-base leading-7 text-zinc-600">
                {feature.description}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
