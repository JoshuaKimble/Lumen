export const resourceFeedbackActions = [
  'save',
  'dismiss',
  'not_helpful',
] as const;

export type ResourceFeedbackAction = (typeof resourceFeedbackActions)[number];

export interface ResourceFeedbackRecord {
  readonly userId: string;
  readonly resourceId: string;
  readonly action: ResourceFeedbackAction;
  readonly entryId?: string;
  readonly themeId?: string;
  readonly note?: string;
}

export class ResourceFeedbackStoreError extends Error {
  constructor(
    readonly code: 'invalid_reference' | 'unavailable',
    message: string,
  ) {
    super(message);
    this.name = 'ResourceFeedbackStoreError';
  }
}

export interface ResourceFeedbackStore {
  saveFeedback(record: ResourceFeedbackRecord): Promise<void>;
}
