import type { DeliveryArtifactMetadata, ReadAloudDeliveryPreference } from "./delivery";

export interface EmailRecipient {
  id: number;
  userId: number;
  name: string;
  email: string;
  isDefault: boolean;
  deviceType: string | null;
  preferredFormat: string | null;
  defaultTemplateId: number | null;
  createdAt: string;
  readAloudDelivery?: ReadAloudDeliveryPreference;
  /** The newest send to this recipient; only the list endpoint fills it. */
  lastSend?: EmailRecipientLastSend | null;
}

export interface EmailRecipientLastSend {
  bookId: number | null;
  bookTitle: string | null;
  status: "pending" | "sent" | "failed";
  createdAt: string;
  /** With failureCode and errorMessage, tells a retry or an unconfirmed send from a plain failure. */
  attemptCount?: number;
  failureCode?: string | null;
  errorMessage?: string | null;
}

export interface EmailRecipientForm {
  name: string;
  email: string;
  deviceType: string | null;
  preferredFormat: string | null;
  defaultTemplateId: number | null;
  readAloudDelivery?: ReadAloudDeliveryPreference;
}

export interface EmailSendLogEntry {
  id: number;
  userId: number;
  bookId: number | null;
  bookFileId: number | null;
  providerId: number | null;
  templateId: number | null;
  toEmail: string;
  toName: string | null;
  subject: string | null;
  status: "pending" | "sent" | "failed";
  attemptCount: number;
  errorMessage: string | null;
  sentAt: string | null;
  createdAt: string;
  deliveryPolicy?: ReadAloudDeliveryPreference;
  sourceRevision?: string | null;
  actualVariant?: string | null;
  artifactId?: string | null;
  deviceType?: string | null;
  recipientId?: number | null;
  failureCode?: string | null;
  dispatchPhase?: string | null;
  deliveryMetadata?: DeliveryArtifactMetadata | null;
  /** When a pending send will be tried again; null once it has settled. */
  nextRetryAt?: string | null;
  /** The book's title at read time; null when the book has since been deleted. */
  bookTitle?: string | null;
  /** The book's authors at read time, comma separated; null when it has none or was deleted. */
  bookAuthors?: string | null;
  /** The file that went out, read through bookFileId. */
  fileFormat?: string | null;
  fileSizeBytes?: number | null;
}

/** GET /email/log/summary: counts across the caller's whole log. */
export interface EmailSendLogSummary {
  total: number;
  failed: number;
  pending: number;
}
