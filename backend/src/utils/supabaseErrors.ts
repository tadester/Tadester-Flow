import type { PostgrestError } from "@supabase/supabase-js";

import { BadRequestError, NotFoundError } from "./errors";

export function handleSupabaseError(error: PostgrestError, fallbackMessage: string): never {
  if (error.code === "PGRST116") {
    throw new NotFoundError("Requested resource was not found.");
  }

  throw new BadRequestError(error.message || fallbackMessage);
}
