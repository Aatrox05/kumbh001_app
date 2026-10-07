const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const { enforceSecurityGuard } = require('./middleware/securityGuard');
const IntegrityCheckerService = require('./services/integrityChecker');
const securityRoutes = require('./routes/security');

dotenv.config();

// Production Safety Check: Fail Fast if NODE_ENV=production without PostgreSQL configuration
if (process.env.NODE_ENV === 'production' && !process.env.POSTGRES_HOST && !process.env.DATABASE_URL) {
  console.error('================================================================');
  console.error('💥 FATAL CONFIGURATION ERROR: NODE_ENV IS SET TO PRODUCTION!');
  console.error('PostgreSQL configuration (POSTGRES_HOST or DATABASE_URL) is missing.');
  console.error('Production deployments MUST NOT silently run on single-node SQLite.');
  console.error('Please configure POSTGRES_HOST or DATABASE_URL in your environment.');
  console.error('================================================================');
  process.exit(1);
}

const { initSchema } = require('./config/database');
const seedData = require('./config/seed');
const { errorHandler, notFoundHandler } = require('./middleware/error');
const { authLimiter, sosLimiter, generalLimiter } = require('./middleware/rateLimit');
const Logger = require('./utils/logger');

// Import Route Handlers
const authRoutes = require('./routes/auth');
const placesRoutes = require('./routes/places');
const eventsRoutes = require('./routes/events');
const announcementsRoutes = require('./routes/announcements');
const emergencyRoutes = require('./routes/emergency');
const sosRoutes = require('./routes/sos');
const lostFoundRoutes = require('./routes/lostFound');
const familySafetyRoutes = require('./routes/familySafety');
const aiRoutes = require('./routes/ai');
const syncRoutes = require('./routes/sync');
const deviceTokensRoutes = require('./routes/deviceTokens');
const parkingRoutes = require('./routes/parking');

const app = express();
app.set('trust proxy', true);

// Security & Request Payload Controls
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '100kb' })); // Restrict payload size to prevent DOS
app.use(express.urlencoded({ extended: true, limit: '100kb' }));

// Global Rate Limiting
app.use('/api/', generalLimiter);

// Apply security guard middleware globally for all routes
app.use(enforceSecurityGuard);

// Register security routes for lock status and unlock actions
app.use('/api/v1/security', securityRoutes);

// API v1 Router Registration with Endpoint-Specific Protection
app.use('/api/v1/auth', authLimiter, authRoutes);
app.use('/api/v1/places', placesRoutes);
app.use('/api/v1/events', eventsRoutes);
app.use('/api/v1/announcements', announcementsRoutes);
app.use('/api/v1/emergency', emergencyRoutes);
app.use('/api/v1/sos', sosLimiter, sosRoutes);
app.use('/api/v1/lost-found', lostFoundRoutes);
app.use('/api/v1/family-safety', familySafetyRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/sync', syncRoutes);
app.use('/api/v1/device-tokens', deviceTokensRoutes);
app.use('/api/v1/parking', parkingRoutes);

// Error Handling Middlewares
app.use(notFoundHandler);
app.use(errorHandler);

// Initialize DB and Seed Data before exporting
initSchema().then(() => {
  seedData();
  // Verify source integrity on startup; will lock system if tampering detected
  IntegrityCheckerService.verifySourceIntegrity().then(result => {
    if (result.status === 'TAMPER_DETECTED') {
      Logger.error('System locked due to source tampering', { incidentId: result.incidentId });
    } else {
      Logger.info('Source integrity check passed');
    }
  }).catch(err => {
    Logger.error('Integrity check failed', { error: err.message });
  });
  Logger.info('Database schema & column migrations completed successfully');
}).catch(err => {
  Logger.error('Failed to initialize database schema', { error: err.message });
});

module.exports = app;
