import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/web/app';

describe('API', () => {
  it('healthz returns ok', async () => {
    const app = await createApp();
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('hash requires api key', async () => {
    const app = await createApp();
    const res = await request(app).post('/hash').send({ value: 'a' });
    expect(res.status).toBe(401);
  });

  it('hash works with api key', async () => {
    process.env.API_KEY = 'test-key';
    const app = await createApp();
    const res = await request(app)
      .post('/hash')
      .set('x-api-key', 'test-key')
      .send({ value: 'a' });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('digest');
  });
});


