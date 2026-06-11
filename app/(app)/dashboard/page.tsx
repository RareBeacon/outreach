const metrics = [
  ["Total Leads", "0"],
  ["Verified Leads", "0"],
  ["Active Campaigns", "0"],
  ["Emails Sent", "0"],
  ["Replies", "0"],
  ["Bounce Rate", "0%"],
  ["Deliverability", "0%"],
  ["Unread Replies", "0"],
];

export default function DashboardPage() {
  return (
    <div>
      <div className="mb-8">
        <h2 className="text-3xl font-bold tracking-tight text-slate-950">
          Dashboard
        </h2>
        <p className="mt-2 text-slate-600">
          Monitor leads, verification, campaigns, Gmail sending, and replies.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {metrics.map(([label, value]) => (
          <div
            key={label}
            className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <p className="text-sm font-medium text-slate-500">{label}</p>
            <p className="mt-3 text-3xl font-bold text-slate-950">{value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
