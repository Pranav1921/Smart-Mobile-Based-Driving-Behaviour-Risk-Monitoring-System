import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import path from 'path';
import { swaggerSpec } from './docs/swagger';
import apiRouter from './routes';
import { errorHandler } from './middleware/error.middleware';
import { auditLogger } from './middleware/audit.middleware';
import { requestLogger } from './config/logger';
import { NotFoundError } from './utils/app-error';

const app = express();

// Security headers and performance compression
app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTTP Request logging
app.use((req, _res, next) => {
  requestLogger.info(`${req.method} ${req.originalUrl} - IP: ${req.ip}`);
  next();
});

// State modification audit logger hook
app.use(auditLogger);

// Endpoint API Rate Limiting protection
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15-minute intervals
  max: 200, // Max 200 checks per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: 'error',
    message: 'Too many request queries sent. Please retry after some minutes.',
  },
});
app.use('/api/', apiLimiter);

// Expose uploaded media directories as static files
const uploadPath = path.resolve(process.env.LOCAL_STORAGE_DIR || './uploads');
app.use('/uploads', express.static(uploadPath));
app.use('/orders-client', express.static(path.join(__dirname, '../../web/orders-client')));
app.use('/dispatch', express.static(path.join(__dirname, '../../web/order-dispatch')));

// API spec mounting
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Mount main routing endpoint
app.use('/api/v1', apiRouter);
app.use('/api', apiRouter);

// Service health-check
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date() });
});

// Catch-all route mapping for 404s
app.use((req, _res, next) => {
  next(
    new NotFoundError(
      `The requested resource URL ${req.originalUrl} was not found`
    )
  );
});

// Connect global centralized error mapping handler
app.use(errorHandler);

export { app };
export default app;
