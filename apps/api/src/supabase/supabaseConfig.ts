export interface SupabaseServerConfig {
  readonly enabled: boolean;
  readonly url: string;
  readonly secretKey: string;
}

export function parseSupabaseServerConfig(
  env: NodeJS.ProcessEnv,
): SupabaseServerConfig {
  const enabled = parseBoolean(env.LUMEN_USE_SUPABASE);

  if (!enabled) {
    return {
      enabled: false,
      url: '',
      secretKey: '',
    };
  }

  return {
    enabled: true,
    url: requireValue(env, 'LUMEN_SUPABASE_URL'),
    secretKey: requireValue(env, 'LUMEN_SUPABASE_SECRET_KEY'),
  };
}

function parseBoolean(value: string | undefined): boolean {
  return value?.trim().toLowerCase() == 'true';
}

function requireValue(env: NodeJS.ProcessEnv, key: string): string {
  const value = env[key]?.trim();
  if (!value) {
    throw new Error(
      `Missing required environment variable ${key} when LUMEN_USE_SUPABASE=true.`,
    );
  }

  return value;
}
