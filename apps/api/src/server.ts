import { createApiServer } from './app.js';
import { parseSupabaseServerConfig } from './supabase/supabaseConfig.js';

const defaultPort = 3000;
const port = Number.parseInt(process.env.PORT ?? `${defaultPort}`, 10);
parseSupabaseServerConfig(process.env);
const server = createApiServer();

server.listen(port, () => {
  console.log(`Lumen API listening on http://localhost:${port}`);
});
