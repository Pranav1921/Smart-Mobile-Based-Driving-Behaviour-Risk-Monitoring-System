import request from 'supertest';

// Mock Redis (ioredis) to prevent connection errors during test imports
jest.mock('ioredis', () => {
  return jest.fn().mockImplementation(() => {
    return {
      on: jest.fn(),
      info: jest.fn(),
      quit: jest.fn().mockResolvedValue('OK'),
    };
  });
});

// Mock BullMQ to prevent connection attempts
jest.mock('bullmq', () => {
  return {
    Queue: jest.fn().mockImplementation(() => {
      return {
        add: jest.fn().mockResolvedValue({ id: 'job-id' }),
        on: jest.fn(),
      };
    }),
    Worker: jest.fn().mockImplementation(() => {
      return {
        on: jest.fn(),
      };
    }),
  };
});

import { app } from '../app';
import { authService } from '../services/auth.service';

// Mock the AuthService module
jest.mock('../services/auth.service');

describe('Authentication Route Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/v1/auth/login', () => {
    it('should authenticate successfully with valid inputs', async () => {
      const mockSession = {
        user: {
          id: 'user-uuid-101',
          email: 'test@fleetguard.ai',
          role: 'DRIVER',
        },
        accessToken: 'mock-access-token-jwt-key',
        refreshToken: 'mock-refresh-token-jwt-key',
      };
      (authService.login as jest.Mock).mockResolvedValue(mockSession);

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'test@fleetguard.ai', password: 'FleetGuard2026!' });

      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.data.accessToken).toBe('mock-access-token-jwt-key');
      expect(authService.login).toHaveBeenCalledWith({
        email: 'test@fleetguard.ai',
        password: 'FleetGuard2026!',
      });
    });

    it('should fail with HTTP 400 when malformed email is supplied', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'not-an-email', password: 'short' });

      expect(res.statusCode).toBe(400);
      expect(res.body.status).toBe('error');
      expect(res.body.errors[0].path).toBe('body.email');
    });
  });
});
