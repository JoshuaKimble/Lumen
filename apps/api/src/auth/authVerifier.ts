export interface AuthenticatedUser {
  readonly id: string;
  readonly email?: string;
}

export class AuthVerificationError extends Error {
  constructor(message = 'Authentication is required.') {
    super(message);
    this.name = 'AuthVerificationError';
  }
}

export interface AuthVerifier {
  verifyAccessToken(accessToken: string): Promise<AuthenticatedUser>;
}
