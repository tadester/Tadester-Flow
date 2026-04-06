import Image from "next/image";
import Link from "next/link";

export function Navbar() {
  return (
    <header className="border-b border-zinc-200/80 bg-white/90 backdrop-blur">
      <div className="container flex min-h-16 items-center justify-between gap-4 py-3">
        <Link href="/" className="flex items-center gap-3 text-zinc-950">
          <Image
            src="/images/OPS.png"
            alt="Tadester Ops"
            width={144}
            height={36}
            priority
            className="h-8 w-auto sm:h-9"
          />
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
