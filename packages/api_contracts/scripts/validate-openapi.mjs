import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const contractPath = path.resolve('openapi/openapi.json');
const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

const requiredPaths = [
  ['get', '/health'],
  ['post', '/v1/entries/rewrite'],
  ['post', '/v1/entries/themes/detect'],
  ['post', '/v1/transcriptions'],
];

const requiredSchemas = [
  'HealthResponse',
  'RewriteEntryRequest',
  'RewriteEntryResponse',
  'DetectThemesRequest',
  'DetectThemesResponse',
  'TranscriptionRequest',
  'TranscriptionResponse',
  'ApiError',
];

function fail(message) {
  console.error(`OpenAPI validation failed: ${message}`);
  process.exitCode = 1;
}

if (contract.openapi !== '3.1.0') {
  fail('expected openapi version 3.1.0');
}

if (!contract.info?.title || !contract.info?.version) {
  fail('expected info.title and info.version');
}

for (const [method, route] of requiredPaths) {
  if (!contract.paths?.[route]?.[method]) {
    fail(`missing ${method.toUpperCase()} ${route}`);
  }
}

for (const schemaName of requiredSchemas) {
  if (!contract.components?.schemas?.[schemaName]) {
    fail(`missing schema ${schemaName}`);
  }
}

if (process.exitCode) {
  process.exit();
}

console.log(`Validated ${contract.info.title} ${contract.info.version}`);
