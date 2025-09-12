import http from 'http';
import { createApp } from './web/app';

const port = Number(process.env.PORT || 3000);

async function start() {
  const app = await createApp();
  const server = http.createServer(app);

  server.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`api listening on port ${port}`);
  });

  const shutdown = (signal: string) => {
    // eslint-disable-next-line no-console
    console.log(`received ${signal}, shutting down...`);
    server.close((err) => {
      if (err) {
        // eslint-disable-next-line no-console
        console.error('error during server close', err);
        process.exit(1);
      }
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

start().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('failed to start server', err);
  process.exit(1);
});


