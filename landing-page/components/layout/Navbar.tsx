import Image from "next/image";
import Link from "next/link";

export function Navbar() {
  return (
    <header className="border-b border-zinc-200/80 bg-white/90 backdrop-blur">
      <div className="container flex min-h-20 items-center justify-between gap-4 py-4">
        <Link href="/" className="flex items-center gap-4 text-zinc-950 sm:gap-5">
          <Image
            src="/images/OPS.png"
            alt="Tadester Ops"
            width={272}
            height={272}
            priority
            className="h-28 w-28 object-contain sm:h-36 sm:w-36"
          />
          <div>
            <p className="text-xl font-semibold tracking-tight text-zinc-950 sm:text-[1.75rem]">
              Tadester Ops
            </p>
            <p className="text-xs font-medium uppercase tracking-[0.18em] text-zinc-500">
              Field Operations
            </p>
          </div>
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
