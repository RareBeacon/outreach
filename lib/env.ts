import { z } from "zod";

const serverEnvSchema = z.object({
  APP_URL: z.string().url().default("http://localhost:3000"),

  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),

  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),

  GOOGLE_CLIENT_ID: z.string().min(1).optional(),
  GOOGLE_CLIENT_SECRET: z.string().min(1).optional(),
  GOOGLE_OAUTH_REDIRECT_URI: z.string().url().optional(),

  ENCRYPTION_KEY: z.string().min(1).optional(),

  CRON_SECRET: z.string().min(1).optional(),

  MAX_DAILY_SENDS: z.coerce.number().int().positive().default(100),
  MAX_HOURLY_SENDS: z.coerce.number().int().positive().default(20),
  DEFAULT_SEND_DELAY_SECONDS: z.coerce.number().int().positive().default(120),
  RANDOM_DELAY_MIN_SECONDS: z.coerce.number().int().nonnegative().default(30),
  RANDOM_DELAY_MAX_SECONDS: z.coerce.number().int().nonnegative().default(180),
  DEFAULT_WORKING_HOURS_START: z.string().default("09:00"),
  DEFAULT_WORKING_HOURS_END: z.string().default("17:00"),
  DEFAULT_WORKING_DAYS: z.string().default("1,2,3,4,5"),

  EMAIL_VERIFICATION_PROVIDER: z
    .enum(["local", "zerobounce", "neverbounce", "bouncer"])
    .default("local"),
});

const clientEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
});

export type ServerEnv = z.infer<typeof serverEnvSchema>;
export type ClientEnv = z.infer<typeof clientEnvSchema>;

export function getServerEnv(): ServerEnv {
  return serverEnvSchema.parse(process.env);
}

export function getClientEnv(): ClientEnv {
  return clientEnvSchema.parse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  });
}
