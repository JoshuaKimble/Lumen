export type JsonObject = Record<string, unknown>;

export class BadRequestError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BadRequestError';
  }
}

export function requireObject(value: unknown): JsonObject {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new BadRequestError('Expected a JSON object.');
  }

  return value as JsonObject;
}

export function requireNonEmptyString(
  body: JsonObject,
  key: string,
): string {
  const value = body[key];

  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new BadRequestError(`Expected non-empty string "${key}".`);
  }

  return value;
}

export function requireBoolean(body: JsonObject, key: string): boolean {
  const value = body[key];

  if (typeof value !== 'boolean') {
    throw new BadRequestError(`Expected boolean "${key}".`);
  }

  return value;
}

export function rejectUnknownKeys(
  body: JsonObject,
  allowedKeys: readonly string[],
): void {
  for (const key of Object.keys(body)) {
    if (!allowedKeys.includes(key)) {
      throw new BadRequestError(`Unexpected field "${key}".`);
    }
  }
}
