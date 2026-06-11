import Link from "next/link";

import { signUpWithPassword } from "@/lib/auth/actions";

type RegisterFormProps = {
  error?: string;
};

export function RegisterForm({ error }: RegisterFormProps) {
  return (
    <form action={signUpWithPassword} className="space-y-5">
      <div>
        <label htmlFor="email" className="block text-sm font-medium text-slate-700">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-900 outline-none transition focus:border-slate-900"
          placeholder="you@example.com"
        />
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium text-slate-700">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="new-password"
          required
          minLength={8}
          className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2 text-slate-900 outline-none transition focus:border-slate-900"
          placeholder="Minimum 8 characters"
        />
      </div>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      <button
        type="submit"
        className="w-full rounded-lg bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800"
      >
        Create account
      </button>

      <p className="text-center text-sm text-slate-600">
        Already have an account?{" "}
        <Link href="/auth/login" className="font-medium text-slate-950 underline">
          Sign in
        </Link>
      </p>
    </form>
  );
}
