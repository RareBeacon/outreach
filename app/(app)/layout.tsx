import type { ReactNode } from "react";

import { SidebarNav } from "@/components/app/sidebar-nav";
import { signOut } from "@/lib/auth/actions";
import { requireUser } from "@/lib/auth/require-user";

type AppLayoutProps = {
  children: ReactNode;
};

export default async function AppLayout({ children }: AppLayoutProps) {
  const user = await requireUser();

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="grid min-h-screen lg:grid-cols-[260px_1fr]">
        <aside className="border-r border-slate-200 bg-white px-4 py-6">
          <div className="mb-8 px-3">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-400">
              Outreach
            </p>
            <h1 className="mt-2 text-lg font-bold text-slate-950">
              Control Center
            </h1>
          </div>

          <SidebarNav />
        </aside>

        <section>
          <header className="border-b border-slate-200 bg-white">
            <div className="flex items-center justify-between px-6 py-4">
              <div>
                <p className="text-sm text-slate-500">Signed in as</p>
                <p className="font-medium text-slate-950">{user.email}</p>
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

          <div className="px-6 py-8">{children}</div>
        </section>
      </div>
    </main>
  );
}
