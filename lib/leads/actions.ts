"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireUser } from "@/lib/auth/require-user";
import { normalizeEmail } from "@/lib/leads/normalize-email";
import { createClient } from "@/lib/supabase/server";
import { leadFormSchema } from "@/lib/validation/lead.schema";

export async function createLead(formData: FormData) {
  const user = await requireUser();

  const parsed = leadFormSchema.safeParse({
    firstName: formData.get("firstName"),
    lastName: formData.get("lastName"),
    company: formData.get("company"),
    website: formData.get("website"),
    email: formData.get("email"),
    phone: formData.get("phone"),
    industry: formData.get("industry"),
    customFields: formData.get("customFields"),
  });

  if (!parsed.success) {
    const message = parsed.error.issues[0]?.message ?? "Invalid lead data.";
    redirect(`/leads?error=${encodeURIComponent(message)}`);
  }

  const supabase = await createClient();
  const data = parsed.data;

  const { error } = await supabase.from("leads").insert({
    user_id: user.id,
    first_name: data.firstName || null,
    last_name: data.lastName || null,
    company: data.company || null,
    website: data.website || null,
    email: data.email,
    phone: data.phone || null,
    industry: data.industry || null,
    custom_fields: data.customFields,
    status: "unknown",
    confidence_score: 0,
  });

  if (error) {
    if (error.code === "23505") {
      redirect(
        `/leads?error=${encodeURIComponent(
          `A lead with ${normalizeEmail(data.email)} already exists.`,
        )}`,
      );
    }

    redirect(`/leads?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/leads");
  redirect("/leads?message=Lead created.");
}

export async function deleteLead(formData: FormData) {
  const user = await requireUser();
  const leadId = String(formData.get("leadId") ?? "");

  if (!leadId) {
    redirect("/leads?error=Missing lead id.");
  }

  const supabase = await createClient();

  const { error } = await supabase
    .from("leads")
    .delete()
    .eq("id", leadId)
    .eq("user_id", user.id);

  if (error) {
    redirect(`/leads?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/leads");
  redirect("/leads?message=Lead deleted.");
}
