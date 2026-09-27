import { StringDecoder } from "node:string_decoder";

export const MAX_OUTPUT_BYTES = 50 * 1024;
export const MAX_OUTPUT_LINES = 2_000;

const TRUNCATION_NOTICE =
  "[Earlier output truncated to the last 50 KiB or 2,000 lines]";

export interface TailTruncationOptions {
  maxBytes: number;
  maxLines: number;
}

export interface TailTruncation {
  content: string;
  truncated: boolean;
}

export type TailTruncator = (
  content: string,
  options: TailTruncationOptions,
) => TailTruncation;

export interface OutputSnapshot {
  text: string;
  truncated: boolean;
}

const compatibleTruncate: TailTruncator = (content, options) => {
  let next = content;
  let truncated = false;
  const lines = next.split("\n");
  if (next.endsWith("\n")) lines.pop();
  if (lines.length > options.maxLines) {
    next = lines.slice(-options.maxLines).join("\n");
    truncated = true;
  }

  const encoded = Buffer.from(next, "utf8");
  if (encoded.byteLength > options.maxBytes) {
    let start = encoded.byteLength - options.maxBytes;
    while (start < encoded.byteLength && (encoded[start] & 0xc0) === 0x80) {
      start += 1;
    }
    next = encoded.subarray(start).toString("utf8");
    truncated = true;
  }

  return { content: next, truncated };
};

export class OutputTail {
  private readonly decoder = new StringDecoder("utf8");
  private readonly truncate: TailTruncator;
  private text = "";
  private truncated = false;
  private finished = false;
  private restoreLineBoundary = false;

  constructor(truncate: TailTruncator = compatibleTruncate) {
    this.truncate = truncate;
  }

  append(chunk: Uint8Array): void {
    if (this.finished) return;
    this.appendDecoded(this.decoder.write(Buffer.from(chunk)));
  }

  finish(): void {
    if (this.finished) return;
    this.finished = true;
    this.appendDecoded(this.decoder.end());
  }

  snapshot(): OutputSnapshot {
    return { text: this.text, truncated: this.truncated };
  }

  format(): string {
    const body = this.text.trimEnd() || "(no output)";
    return this.truncated ? `${TRUNCATION_NOTICE}\n${body}` : body;
  }

  private appendDecoded(decoded: string): void {
    if (decoded.length === 0) return;
    if (this.restoreLineBoundary) {
      this.text += "\n";
      this.restoreLineBoundary = false;
    }
    this.text += decoded;
    this.trim();
  }

  private trim(): void {
    const endedWithNewline = this.text.endsWith("\n");
    const next = this.truncate(this.text, {
      maxBytes: MAX_OUTPUT_BYTES,
      maxLines: MAX_OUTPUT_LINES,
    });
    this.text = next.content;
    this.truncated ||= next.truncated;
    this.restoreLineBoundary =
      next.truncated && endedWithNewline && !next.content.endsWith("\n");
  }
}
