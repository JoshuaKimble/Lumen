import { createApiServer } from './app.js';

const defaultPort = 3000;
const port = Number.parseInt(process.env.PORT ?? `${defaultPort}`, 10);
const server = createApiServer();

server.listen(port, () => {
  console.log(`Lumen API listening on http://localhost:${port}`);
});
