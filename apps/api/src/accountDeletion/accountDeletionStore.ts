export class AccountDeletionStoreError extends Error {
  constructor(
    readonly code: 'not_found' | 'unavailable',
    message: string,
  ) {
    super(message);
    this.name = 'AccountDeletionStoreError';
  }
}

export interface AccountDeletionStore {
  deleteAccount(userId: string): Promise<void>;
}
