import { signOut } from "@/lib/auth/actions";
import { requireUser } from "@/lib/auth/require-user";

export default async function DashboardPage() {
  const user = await requireUser();

  return (
    <main className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div>
            <p className="text-sm font-semibold uppercase tracking-wide text-slate-500">
              Outreach Platform
            </p>
            <h1 className="text-xl font-bold text-slate-950">Dashboard</h1>
          </div>

          <form action={signOut}>
            <button
              type="submit"
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100"
            >
              Sign out
            </button>
          </form>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-2xl font-bold tracking-tight text-slate-950">
            Welcome
          </h2>
          <p className="mt-2 text-slate-600">
            Signed in as <span className="font-medium">{user.email}</span>.
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[
            ["Total Leads", "0"],
            ["Verified Leads", "0"],
            ["Active Campaigns", "0"],
            ["Emails Sent", "0"],
          ].map(([label, value]) => (
            <div
              key={label}
              className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <p className="text-sm font-medium text-slate-500">{label}</p>
              <p className="mt-3 text-3xl font-bold text-slate-950">{value}</p>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
