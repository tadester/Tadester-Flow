import Link from "next/link";

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-zinc-200 bg-white">
      <div className="container flex flex-col gap-4 py-8 text-sm text-zinc-600 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <span className="font-semibold text-zinc-900">Tadester Ops</span>
          <p className="mt-1 text-sm text-zinc-500">
            © {year} Tadester Ops. All rights reserved.
          </p>
        </div>
        <nav className="flex gap-5">
          <Link href="/privacy" className="transition hover:text-zinc-900">
            Privacy
          </Link>
          <Link href="/terms" className="transition hover:text-zinc-900">
            Terms
          </Link>
        </nav>
      </div>
    </footer>
  );
}
