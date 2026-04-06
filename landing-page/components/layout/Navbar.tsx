import Link from "next/link";

export function Navbar() {
  return (
    <header className="border-b border-zinc-200/80 bg-white/90 backdrop-blur">
      <div className="container flex min-h-16 items-center justify-between gap-4 py-3">
        <Link href="/" className="text-xl font-semibold tracking-tight text-zinc-950">
          <span className="font-bold">Tadester</span> Ops
        </Link>
        <a
          href="#waitlist"
          className="inline-flex rounded-lg border border-zinc-900 px-4 py-2 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-900 hover:text-white"
        >
          Join Waitlist
        </a>
      </div>
    </header>
  );
}
