import { Request, Response } from 'express';
import { ProjectModel } from '../models/Project.js';
import type { MaterialList, CuttingPlan, AssemblyStep } from '../../../shared/types/index.js';
import { v4 as uuidv4 } from 'uuid';

// Get all projects
export const getAllProjects = async (req: Request, res: Response) => {
  try {
    const projects = await ProjectModel.find().sort({ updatedAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
};

// Get project by ID
export const getProjectById = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }
    res.json(project);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch project' });
  }
};

// Create new project
export const createProject = async (req: Request, res: Response) => {
  try {
    const project = new ProjectModel(req.body);
    await project.save();
    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create project' });
  }
};

// Update project
export const updateProject = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }
    res.json(project);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update project' });
  }
};

// Delete project
export const deleteProject = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findByIdAndDelete(req.params.id);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }
    res.json({ message: 'Project deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete project' });
  }
};

// Generate material list
export const generateMaterialList = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Group pieces by wood type and dimensions
    const woodMap = new Map<string, any>();
    project.pieces.forEach((piece) => {
      const key = `${piece.woodType}-${piece.dimensions.length}x${piece.dimensions.width}x${piece.dimensions.thickness}`;
      if (woodMap.has(key)) {
        woodMap.get(key).quantity += 1;
      } else {
        woodMap.set(key, {
          woodType: piece.woodType,
          dimensions: piece.dimensions,
          quantity: 1,
        });
      }
    });

    // Group fastenings
    const fasteningMap = new Map<string, any>();
    project.fastenings.forEach((fastening) => {
      const key = `${fastening.type}-${JSON.stringify(fastening.specifications)}`;
      if (fasteningMap.has(key)) {
        fasteningMap.get(key).quantity += 1;
      } else {
        fasteningMap.set(key, {
          type: fastening.type,
          specifications: fastening.specifications,
          quantity: 1,
        });
      }
    });

    const materialList: MaterialList = {
      wood: Array.from(woodMap.values()),
      fastenings: Array.from(fasteningMap.values()),
    };

    res.json(materialList);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate material list' });
  }
};

// Generate cutting plan (basic implementation)
export const generateCuttingPlan = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const { sheetLength, sheetWidth, sheetThickness, woodType } = req.body;

    // Simple cutting plan - pack pieces sequentially
    const cuts: any[] = [];
    let currentX = 0;
    let currentY = 0;
    let rowHeight = 0;

    project.pieces
      .filter((p) => p.woodType === woodType)
      .forEach((piece) => {
        if (currentX + piece.dimensions.length > sheetLength) {
          currentX = 0;
          currentY += rowHeight;
          rowHeight = 0;
        }

        cuts.push({
          pieceId: piece.id,
          position: { x: currentX, y: currentY },
          dimensions: {
            length: piece.dimensions.length,
            width: piece.dimensions.width,
          },
        });

        currentX += piece.dimensions.length;
        rowHeight = Math.max(rowHeight, piece.dimensions.width);
      });

    const usedArea = cuts.reduce((sum, cut) => sum + cut.dimensions.length * cut.dimensions.width, 0);
    const totalArea = sheetLength * sheetWidth;
    const wastePercentage = ((totalArea - usedArea) / totalArea) * 100;

    const cuttingPlan: CuttingPlan = {
      sheet: { length: sheetLength, width: sheetWidth, thickness: sheetThickness, woodType },
      cuts,
      wastePercentage,
    };

    res.json(cuttingPlan);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate cutting plan' });
  }
};

// Generate assembly guide
export const generateAssemblyGuide = async (req: Request, res: Response) => {
  try {
    const project = await ProjectModel.findById(req.params.id);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const steps: AssemblyStep[] = [];

    // Step 1: Prepare all pieces
    steps.push({
      stepNumber: 1,
      title: 'Prepare all wood pieces',
      description: 'Cut and sand all wood pieces to the specified dimensions.',
      pieces: project.pieces.map((p) => p.id),
      fastenings: [],
      tools: ['table saw', 'miter saw', 'sandpaper', 'measuring tape'],
      estimatedTime: project.pieces.length * 10,
      safetyNotes: [
        'Always wear safety glasses when cutting',
        'Keep hands away from saw blade',
        'Use push sticks for small pieces',
      ],
    });

    // Group fastenings by connected pieces
    const assemblyGroups = new Map<string, any[]>();
    project.fastenings.forEach((fastening) => {
      const key = fastening.connectedPieces.sort().join('-');
      if (!assemblyGroups.has(key)) {
        assemblyGroups.set(key, []);
      }
      assemblyGroups.get(key)?.push(fastening);
    });

    // Create steps for each assembly group
    let stepNumber = 2;
    assemblyGroups.forEach((fastenings, key) => {
      const pieces = key.split('-');
      const piece1 = project.pieces.find((p) => p.id === pieces[0]);
      const piece2 = project.pieces.find((p) => p.id === pieces[1]);

      if (piece1 && piece2) {
        const tools = fastenings.map((f) => {
          switch (f.type) {
            case 'screw':
            case 'wood-screw':
              return 'drill with driver bit';
            case 'nail':
              return 'hammer';
            case 'glue':
              return 'wood glue and clamps';
            case 'dovetail':
              return 'dovetail jig and router';
            case 'mortise-tenon':
              return 'chisel and mallet';
            default:
              return 'appropriate tools';
          }
        });

        steps.push({
          stepNumber: stepNumber++,
          title: `Attach ${piece1.name} to ${piece2.name}`,
          description: `Join these pieces using ${fastenings.map((f) => f.type).join(', ')}.`,
          pieces: [piece1.id, piece2.id],
          fastenings: fastenings.map((f) => f.id),
          tools: [...new Set(tools)],
          estimatedTime: 15,
          safetyNotes: ['Ensure pieces are properly aligned', 'Apply even pressure when fastening'],
        });
      }
    });

    // Final step
    steps.push({
      stepNumber: stepNumber,
      title: 'Final inspection and finishing',
      description: 'Inspect all joints, apply finish as desired, and let dry completely.',
      pieces: project.pieces.map((p) => p.id),
      fastenings: [],
      tools: ['sandpaper', 'wood finish', 'brushes'],
      estimatedTime: 60,
      safetyNotes: ['Work in well-ventilated area', 'Wear appropriate respirator for finishes'],
    });

    res.json(steps);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate assembly guide' });
  }
};
