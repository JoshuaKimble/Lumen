import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

import { createApiServer } from '../src/app.js';

let baseUrl = '';
const server = createApiServer();

before(async () => {
  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  server.closeAllConnections();
  server.closeIdleConnections();

  await new Promise<void>((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
});

test('health endpoint returns service status', async () => {
  const response = await fetch(`${baseUrl}/health`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    status: 'ok',
    service: 'lumen-api',
  });
});
