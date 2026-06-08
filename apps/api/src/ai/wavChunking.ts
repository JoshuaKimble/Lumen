import { Buffer } from 'node:buffer';

const riffHeaderSize = 12;
const chunkHeaderSize = 8;
const pcmFormatCode = 1;
const minimumFmtChunkLength = 16;

interface ParsedWaveFile {
  readonly fmtChunkData: Uint8Array;
  readonly audioFormat: number;
  readonly sampleRate: number;
  readonly byteRate: number;
  readonly blockAlign: number;
  readonly bitsPerSample: number;
  readonly data: Uint8Array;
}

export function splitWaveAudio(
  audio: Uint8Array,
  maxChunkDurationSeconds: number,
): readonly Uint8Array[] {
  const parsed = parseWaveFile(audio);
  if (parsed == null) {
    return [audio];
  }

  if (parsed.audioFormat !== pcmFormatCode) {
    return [audio];
  }

  const maxChunkBytes = alignedChunkByteLength(
    parsed.byteRate,
    parsed.blockAlign,
    maxChunkDurationSeconds,
  );

  if (maxChunkBytes <= 0 || parsed.data.byteLength <= maxChunkBytes) {
    return [audio];
  }

  const chunks: Uint8Array[] = [];
  for (let offset = 0; offset < parsed.data.byteLength; offset += maxChunkBytes) {
    const end = Math.min(offset + maxChunkBytes, parsed.data.byteLength);
    const dataChunk = parsed.data.slice(offset, end);
    chunks.push(buildWaveFile(parsed, dataChunk));
  }

  return chunks;
}

function parseWaveFile(audio: Uint8Array): ParsedWaveFile | null {
  if (audio.byteLength < riffHeaderSize) {
    return null;
  }

  const bytes = Buffer.from(audio);
  if (
    bytes.toString('ascii', 0, 4) !== 'RIFF' ||
    bytes.toString('ascii', 8, 12) !== 'WAVE'
  ) {
    return null;
  }

  let offset = riffHeaderSize;
  let fmtChunkData: Uint8Array | undefined;
  let dataChunk: Uint8Array | undefined;

  while (offset + chunkHeaderSize <= bytes.byteLength) {
    const chunkId = bytes.toString('ascii', offset, offset + 4);
    const chunkSize = bytes.readUInt32LE(offset + 4);
    const chunkStart = offset + chunkHeaderSize;
    const chunkEnd = chunkStart + chunkSize;

    if (chunkEnd > bytes.byteLength) {
      return null;
    }

    if (chunkId === 'fmt ') {
      fmtChunkData = audio.slice(chunkStart, chunkEnd);
    } else if (chunkId === 'data') {
      dataChunk = audio.slice(chunkStart, chunkEnd);
    }

    offset = chunkEnd + (chunkSize % 2);
  }

  if (fmtChunkData == null || dataChunk == null) {
    return null;
  }

  if (fmtChunkData.byteLength < minimumFmtChunkLength) {
    return null;
  }

  const fmtView = Buffer.from(fmtChunkData);
  return {
    fmtChunkData,
    audioFormat: fmtView.readUInt16LE(0),
    sampleRate: fmtView.readUInt32LE(4),
    byteRate: fmtView.readUInt32LE(8),
    blockAlign: fmtView.readUInt16LE(12),
    bitsPerSample: fmtView.readUInt16LE(14),
    data: dataChunk,
  };
}

function alignedChunkByteLength(
  byteRate: number,
  blockAlign: number,
  maxChunkDurationSeconds: number,
): number {
  if (byteRate <= 0 || blockAlign <= 0 || maxChunkDurationSeconds <= 0) {
    return 0;
  }

  const rawByteLength = Math.floor(byteRate * maxChunkDurationSeconds);
  return rawByteLength - (rawByteLength % blockAlign);
}

function buildWaveFile(parsed: ParsedWaveFile, data: Uint8Array): Uint8Array {
  const fmtChunkLength = parsed.fmtChunkData.byteLength;
  const riffChunkLength = 4 + (chunkHeaderSize + fmtChunkLength) + (chunkHeaderSize + data.byteLength);
  const buffer = Buffer.allocUnsafe(riffHeaderSize + chunkHeaderSize + fmtChunkLength + chunkHeaderSize + data.byteLength);

  buffer.write('RIFF', 0, 'ascii');
  buffer.writeUInt32LE(riffChunkLength, 4);
  buffer.write('WAVE', 8, 'ascii');

  buffer.write('fmt ', 12, 'ascii');
  buffer.writeUInt32LE(fmtChunkLength, 16);
  Buffer.from(parsed.fmtChunkData).copy(buffer, 20);

  const dataChunkOffset = 20 + fmtChunkLength;
  buffer.write('data', dataChunkOffset, 'ascii');
  buffer.writeUInt32LE(data.byteLength, dataChunkOffset + 4);
  Buffer.from(data).copy(buffer, dataChunkOffset + chunkHeaderSize);

  return new Uint8Array(buffer);
}
