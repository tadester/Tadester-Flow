export function OperatorQuote() {
  return (
    <section className="section">
      <div className="container grid gap-10 lg:grid-cols-[1.05fr_1fr] lg:items-center">
        <div className="space-y-6">
          <div className="flex items-start gap-4">
            <div className="h-20 w-20 shrink-0 rounded-2xl bg-[linear-gradient(145deg,#1f7a8c,#16425b)]" />
            <div>
              <span className="eyebrow">Built for teams in Edmonton</span>
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
          <div className="relative min-h-[440px] bg-[radial-gradient(circle_at_25%_25%,#efe6cf,transparent_22%),radial-gradient(circle_at_68%_42%,#f2c86b,transparent_18%),linear-gradient(135deg,#e7d8b5_10%,#f2e6cd_34%,#d5b67a_62%,#b7894d_100%)]">
            <div className="absolute inset-0 opacity-40 [background-image:linear-gradient(rgba(34,34,34,0.5)_2px,transparent_2px),linear-gradient(90deg,rgba(34,34,34,0.5)_2px,transparent_2px)] [background-size:92px_92px]" />
            <div className="absolute left-[12%] top-[22%] h-[2px] w-[58%] rotate-[12deg] bg-zinc-900/70" />
            <div className="absolute left-[28%] top-[18%] h-[2px] w-[48%] rotate-[34deg] bg-zinc-900/70" />
            <div className="absolute left-[22%] top-[46%] h-[2px] w-[42%] rotate-[-16deg] bg-zinc-900/70" />
            <div className="absolute left-[58%] top-[51%] h-[2px] w-[26%] rotate-[25deg] bg-zinc-900/70" />
            <div className="absolute left-[29%] top-[38%] h-3 w-3 rounded-full bg-[#d90d0d] shadow-[0_0_0_10px_rgba(217,13,13,0.14)]" />
            <div className="absolute left-[63%] top-[53%] h-3 w-3 rounded-full bg-[#d90d0d] shadow-[0_0_0_10px_rgba(217,13,13,0.14)]" />
          </div>
        </div>
      </div>
    </section>
  );
}
