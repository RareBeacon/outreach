import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950 px-6 py-12 text-white">
      <section className="max-w-3xl text-center">
        <p className="text-sm font-semibold uppercase tracking-[0.3em] text-slate-400">
          Self-hosted Outreach
        </p>
        <h1 className="mt-6 text-5xl font-bold tracking-tight md:text-6xl">
          Your private cold email operating system.
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          Upload leads, verify email addresses, write your own templates,
          personalize messages, send through Gmail, and track replies.
        </p>

        <div className="mt-10 flex flex-col justify-center gap-3 sm:flex-row">
          <Link
            href="/auth/login"
            className="rounded-lg bg-white px-5 py-3 text-sm font-semibold text-slate-950 transition hover:bg-slate-200"
          >
            Sign in
          </Link>
          <Link
            href="/auth/register"
            className="rounded-lg border border-slate-700 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-900"
          >
            Create account
          </Link>
        </div>
      </section>
    </main>
  );
}
