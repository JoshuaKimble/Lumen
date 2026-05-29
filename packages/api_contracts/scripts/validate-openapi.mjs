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
  ['post', '/v1/resources/suggest'],
  ['post', '/v1/resources/feedback'],
];

const requiredSchemas = [
  'HealthResponse',
  'RewriteEntryRequest',
  'RewriteEntryResponse',
  'DetectThemesRequest',
  'DetectThemesResponse',
  'TranscriptionRequest',
  'TranscriptionResponse',
  'SuggestResourcesRequest',
  'SuggestResourcesResponse',
  'RelatedResourceSuggestion',
  'ResourceFeedbackRequest',
  'ResourceFeedbackResponse',
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

if (!contract.components?.securitySchemes?.bearerAuth) {
  fail('missing security scheme bearerAuth');
}

const resourceFeedbackOperation = contract.paths?.['/v1/resources/feedback']?.post;
if (!resourceFeedbackOperation) {
  fail('missing POST /v1/resources/feedback');
} else {
  const hasBearerSecurity = Array.isArray(resourceFeedbackOperation.security)
    && resourceFeedbackOperation.security.some((item) => item?.bearerAuth);
  if (!hasBearerSecurity) {
    fail('expected POST /v1/resources/feedback to require bearerAuth');
  }

  for (const statusCode of ['401', '403']) {
    if (!resourceFeedbackOperation.responses?.[statusCode]) {
      fail(`expected POST /v1/resources/feedback to define ${statusCode} response`);
    }
  }
}

if (process.exitCode) {
  process.exit();
}

console.log(`Validated ${contract.info.title} ${contract.info.version}`);
