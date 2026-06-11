"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

const authSchema = z.object({
  email: z.string().email("Enter a valid email address."),
  password: z.string().min(8, "Password must be at least 8 characters."),
});

function getAuthCredentials(formData: FormData) {
  return authSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });
}

export async function signInWithPassword(formData: FormData) {
  const parsed = getAuthCredentials(formData);

  if (!parsed.success) {
    redirect("/auth/login?error=Invalid email or password format.");
  }

  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithPassword(parsed.data);

  if (error) {
    redirect(`/auth/login?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/", "layout");
  redirect("/dashboard");
}

export async function signUpWithPassword(formData: FormData) {
  const parsed = getAuthCredentials(formData);

  if (!parsed.success) {
    redirect("/auth/register?error=Invalid email or password format.");
  }

  const supabase = await createClient();

  const { error } = await supabase.auth.signUp(parsed.data);

  if (error) {
    redirect(`/auth/register?error=${encodeURIComponent(error.message)}`);
  }

  redirect("/auth/login?message=Account created. Check your email if confirmation is enabled.");
}

export async function signOut() {
  const supabase = await createClient();

  await supabase.auth.signOut();

  revalidatePath("/", "layout");
  redirect("/auth/login");
}
