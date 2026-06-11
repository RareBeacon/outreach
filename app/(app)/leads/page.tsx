import { LeadsTable } from "@/components/leads/leads-table";
import { NewLeadForm } from "@/components/leads/new-lead-form";
import { requireUser } from "@/lib/auth/require-user";
import { createClient } from "@/lib/supabase/server";

type LeadsPageProps = {
  searchParams: Promise<{
    error?: string;
    message?: string;
  }>;
};

export default async function LeadsPage({ searchParams }: LeadsPageProps) {
  const user = await requireUser();
  const params = await searchParams;
  const supabase = await createClient();

  const { data: leads, error } = await supabase
    .from("leads")
    .select(
      "id, first_name, last_name, company, email, industry, status, confidence_score, created_at",
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  return (
    <div>
      <div className="mb-8 flex flex-col justify-between gap-4 lg:flex-row lg:items-end">
        <div>
          <h2 className="text-3xl font-bold tracking-tight text-slate-950">Leads</h2>
          <p className="mt-2 text-slate-600">
            Manage leads, custom fields, duplicate detection, and verification status.
          </p>
        </div>
      </div>

      {params.error ? (
        <div className="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {params.error}
        </div>
      ) : null}

      {params.message ? (
        <div className="mb-6 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
          {params.message}
        </div>
      ) : null}

      {error ? (
        <div className="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error.message}
        </div>
      ) : null}

      <div className="grid gap-6 xl:grid-cols-[420px_1fr]">
        <NewLeadForm />
        <LeadsTable leads={leads ?? []} />
      </div>
    </div>
  );
}
