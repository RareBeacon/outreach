import { RegisterForm } from "@/components/auth/register-form";

type RegisterPageProps = {
  searchParams: Promise<{
    error?: string;
  }>;
};

export default async function RegisterPage({ searchParams }: RegisterPageProps) {
  const params = await searchParams;

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-6 py-12">
      <section className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="mb-8">
          <p className="text-sm font-semibold uppercase tracking-wide text-slate-500">
            Outreach Platform
          </p>
          <h1 className="mt-2 text-3xl font-bold tracking-tight text-slate-950">
            Create account
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            Create your private outreach workspace.
          </p>
        </div>

        <RegisterForm error={params.error} />
      </section>
    </main>
  );
}
