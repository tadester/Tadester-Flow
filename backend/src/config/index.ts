import dotenv from "dotenv";

dotenv.config();

function requireEnv(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

const portValue = requireEnv("PORT");
const port = Number(portValue);

if (Number.isNaN(port)) {
  throw new Error("PORT must be a valid number.");
}

export const config = {
  port,
  supabaseUrl: requireEnv("SUPABASE_URL"),
} as const;
