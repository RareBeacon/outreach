import { deleteLead } from "@/lib/leads/actions";

type Lead = {
  id: string;
  first_name: string | null;
  last_name: string | null;
  company: string | null;
  email: string;
  industry: string | null;
  status: string;
  confidence_score: number;
  created_at: string;
};

type LeadsTableProps = {
  leads: Lead[];
};

export function LeadsTable({ leads }: LeadsTableProps) {
  if (leads.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-8 text-center">
        <h3 className="text-lg font-semibold text-slate-950">No leads yet</h3>
        <p className="mt-2 text-sm text-slate-600">
          Add your first lead manually, then we’ll add CSV upload next.
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <table className="min-w-full divide-y divide-slate-200">
        <thead className="bg-slate-50">
          <tr>
            {["Name", "Email", "Company", "Industry", "Status", "Score", ""].map((heading) => (
              <th
                key={heading}
                className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500"
              >
                {heading}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-200">
          {leads.map((lead) => {
            const name = [lead.first_name, lead.last_name].filter(Boolean).join(" ") || "—";

            return (
              <tr key={lead.id}>
                <td className="whitespace-nowrap px-4 py-3 text-sm font-medium text-slate-950">
                  {name}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  {lead.email}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  {lead.company || "—"}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  {lead.industry || "—"}
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm">
                  <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
                    {lead.status}
                  </span>
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-700">
                  {lead.confidence_score}%
                </td>
                <td className="whitespace-nowrap px-4 py-3 text-right text-sm">
                  <form action={deleteLead}>
                    <input type="hidden" name="leadId" value={lead.id} />
                    <button
                      type="submit"
                      className="text-sm font-medium text-red-600 hover:text-red-700"
                    >
                      Delete
                    </button>
                  </form>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
