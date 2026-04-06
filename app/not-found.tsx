import Link from "next/link";

export default function NotFound() {
  return (
    <main className="section">
      <div className="container">
        <div className="surface-card mx-auto flex max-w-2xl flex-col items-center gap-6 px-6 py-14 text-center sm:px-10">
          <span className="eyebrow">404</span>
          <h1 className="section-title">That page is off route.</h1>
          <p className="section-copy">
            The page you were looking for does not exist or may have moved.
          </p>
          <Link
            href="/"
            className="inline-flex rounded-xl border border-zinc-900 px-5 py-3 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-900 hover:text-white"
          >
            Back to homepage
          </Link>
        </div>
      </div>
    </main>
  );
}
