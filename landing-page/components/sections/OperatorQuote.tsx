import Image from "next/image";

export function OperatorQuote() {
  return (
    <section className="section">
      <div className="container grid gap-10 lg:grid-cols-[1.05fr_1fr] lg:items-center">
        <div className="space-y-6">
          <div className="flex items-start gap-4">
            <div className="relative h-20 w-20 shrink-0 overflow-hidden rounded-2xl">
              <Image
                src="/images/operator-team.jpg"
                alt="Field operators working together outdoors"
                fill
                className="object-cover"
                sizes="80px"
              />
            </div>
            <div>
              <span className="eyebrow">Built for field teams worldwide</span>
              <blockquote className="mt-3 max-w-2xl text-[1.85rem] italic leading-[1.45] text-zinc-800">
                “We understand the unique challenges of field operations in
                harsh climates. Tadester Ops is built by operators, for
                operators.”
              </blockquote>
            </div>
          </div>

          <div className="pt-8">
            <h2 className="section-title">Built for the field</h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-zinc-600">
              Your crews work in tough conditions. Your software should work
              just as hard. Tadester Ops eliminates guesswork, reduces fuel
              costs, and keeps every job on schedule.
            </p>
            <ul className="mt-6 space-y-4">
              {[
                "No manual route planning",
                "Automatic time tracking",
                "Live crew visibility",
              ].map((item) => (
                <li key={item} className="flex items-center gap-3 text-base text-zinc-700">
                  <span className="h-2 w-2 rounded-full bg-[#d90d0d]" />
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="surface-card overflow-hidden rounded-[24px]">
          <div className="relative min-h-[440px]">
            <Image
              src="/images/routing-map.png"
              alt="Route map used for dispatch and field planning"
              fill
              className="object-cover"
              style={{ objectPosition: "center" }}
              sizes="(max-width: 1024px) 100vw, 520px"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
