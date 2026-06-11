import { z } from "zod";

const customFieldsSchema = z
  .string()
  .optional()
  .transform((value, ctx) => {
    if (!value || value.trim() === "") {
      return {};
    }

    try {
      const parsed = JSON.parse(value);

      if (
        typeof parsed !== "object" ||
        parsed === null ||
        Array.isArray(parsed)
      ) {
        ctx.addIssue({
          code: "custom",
          message: "Custom fields must be a JSON object.",
        });

        return z.NEVER;
      }

      return parsed as Record<string, unknown>;
    } catch {
      ctx.addIssue({
        code: "custom",
        message: "Custom fields must be valid JSON.",
      });

      return z.NEVER;
    }
  });

export const leadFormSchema = z.object({
  firstName: z.string().trim().optional(),
  lastName: z.string().trim().optional(),
  company: z.string().trim().optional(),
  website: z.string().trim().optional(),
  email: z.string().trim().email("Enter a valid email address."),
  phone: z.string().trim().optional(),
  industry: z.string().trim().optional(),
  customFields: customFieldsSchema,
});

export type LeadFormInput = z.input<typeof leadFormSchema>;
export type LeadFormData = z.output<typeof leadFormSchema>;
