export interface SupabaseServerConfig {
  readonly enabled: boolean;
  readonly url: string;
  readonly serviceRoleKey: string;
}

export function parseSupabaseServerConfig(
  env: NodeJS.ProcessEnv,
): SupabaseServerConfig {
  const enabled = parseBoolean(env.LUMEN_USE_SUPABASE);

  if (!enabled) {
    return {
      enabled: false,
      url: '',
      serviceRoleKey: '',
    };
  }

  return {
    enabled: true,
    url: requireValue(env, 'LUMEN_SUPABASE_URL'),
    serviceRoleKey: requireValue(env, 'LUMEN_SUPABASE_SERVICE_ROLE_KEY'),
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
