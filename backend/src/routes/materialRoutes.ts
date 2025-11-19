import express from 'express';
import { getWoodTypes, getFasteningTypes } from '../controllers/materialController.js';

const router = express.Router();

router.get('/wood-types', getWoodTypes);
router.get('/fastening-types', getFasteningTypes);

export default router;
