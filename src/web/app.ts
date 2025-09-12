import express, { Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import pinoHttp from 'pino-http';
import { collectDefaultMetrics, Counter, Registry } from 'prom-client';
import crypto from 'crypto';
import onFinished from 'on-finished';

export async function createApp() {
  const app = express();
  const registry = new Registry();
  collectDefaultMetrics({ register: registry });

  const requestsCounter = new Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'path', 'status'] as const,
    registers: [registry],
  });

  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '256kb' }));
  app.use(pinoHttp());

  // Readiness and liveness
  app.get('/healthz', (_req, res) => res.status(200).json({ status: 'ok' }));
  let isReady = true;
  app.get('/ready', (_req, res) => {
    if (isReady) return res.status(200).json({ ready: true });
    return res.status(503).json({ ready: false });
  });

  // Simple API key middleware for non-health endpoints
  app.use((req: Request, res: Response, next: NextFunction) => {
    if (req.path === '/healthz' || req.path === '/ready' || req.path === '/metrics') {
      return next();
    }
    const apiKey = req.header('x-api-key');
    if (!apiKey || apiKey !== (process.env.API_KEY || 'changeme')) {
      return res.status(401).json({ error: 'unauthorized' });
    }
    return next();
  });

  // Sample JSON operation: hash a string with SHA-256
  app.post('/hash', (req: Request, res: Response) => {
    const { value } = req.body as { value?: string };
    if (typeof value !== 'string') {
      return res.status(400).json({ error: 'value must be a string' });
    }
    const digest = crypto.createHash('sha256').update(value).digest('hex');
    return res.status(200).json({ algorithm: 'sha256', digest });
  });

  // Metrics endpoint
  app.get('/metrics', async (_req: Request, res: Response) => {
    res.setHeader('Content-Type', registry.contentType);
    const body = await registry.metrics();
    res.send(body);
  });

  // Basic request counter middleware using on-finished
  app.use((req: Request, res: Response, next: NextFunction) => {
    onFinished(res, () => {
      try {
        requestsCounter.inc({ method: req.method, path: req.route?.path || req.path, status: String(res.statusCode) });
      } catch {
        // ignore metrics errors
      }
    });
    next();
  });

  // Error handler
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    // eslint-disable-next-line no-console
    console.error('unhandled error', err);
    res.status(500).json({ error: 'internal_error' });
  });

  return app;
}


