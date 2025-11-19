import express from 'express';
import {
  getAllProjects,
  getProjectById,
  createProject,
  updateProject,
  deleteProject,
  generateMaterialList,
  generateCuttingPlan,
  generateAssemblyGuide,
} from '../controllers/projectController.js';

const router = express.Router();

router.get('/', getAllProjects);
router.get('/:id', getProjectById);
router.post('/', createProject);
router.put('/:id', updateProject);
router.delete('/:id', deleteProject);

// Additional features
router.post('/:id/material-list', generateMaterialList);
router.post('/:id/cutting-plan', generateCuttingPlan);
router.post('/:id/assembly-guide', generateAssemblyGuide);

export default router;
