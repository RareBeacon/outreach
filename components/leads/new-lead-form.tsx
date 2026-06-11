import { createLead } from "@/lib/leads/actions";

export function NewLeadForm() {
  return (
    <form action={createLead} className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-slate-950">Add lead</h3>
        <p className="mt-1 text-sm text-slate-600">
          Add a lead manually. CSV import will use the same data model.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Field label="First name" name="firstName" autoComplete="given-name" />
        <Field label="Last name" name="lastName" autoComplete="family-name" />
        <Field label="Company" name="company" />
        <Field label="Website" name="website" placeholder="https://example.com" />
        <Field label="Email" name="email" type="email" required autoComplete="email" />
        <Field label="Phone" name="phone" autoComplete="tel" />
        <Field label="Industry" name="industry" />
      </div>

      <div className="mt-4">
        <label htmlFor="customFields" className="block text-sm font-medium text-slate-700">
          Custom fields JSON
        </label>
        <textarea
          id="customFields"
          name="customFields"
          rows={5}
          className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2 font-mono text-sm text-slate-900 outline-none transition focus:border-slate-900"
          placeholder='{"jobTitle":"Founder","city":"Lagos"}'
        />
        <p className="mt-2 text-xs text-slate-500">
          These keys become available as template variables, e.g. {"{{jobTitle}}"}.
        </p>
      </div>

      <button
        type="submit"
        className="mt-5 rounded-lg bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800"
      >
        Create lead
      </button>
    </form>
  );
}

type FieldProps = {
  label: string;
  name: string;
  type?: string;
  required?: boolean;
  placeholder?: string;
  autoComplete?: string;
};

function Field({
  label,
  name,
  type = "text",
  required = false,
  placeholder,
  autoComplete,
}: FieldProps) {
  return (
    <div>
      <label htmlFor={name} className="block text-sm font-medium text-slate-700">
        {label}
      </label>
      <input
        id={name}
        name={name}
        type={type}
        required={required}
        placeholder={placeholder}
        autoComplete={autoComplete}
        className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-900 outline-none transition focus:border-slate-900"
      />
    </div>
  );
}
