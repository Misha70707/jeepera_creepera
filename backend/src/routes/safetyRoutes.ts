import express from 'express';
import { getSafetyTips } from '../controllers/safetyController.js';

const router = express.Router();

router.get('/tips', getSafetyTips);

export default router;
