import { Request, Response } from 'express';
import type { WoodProperties } from '../../../shared/types/index.js';

const woodTypes: WoodProperties[] = [
  {
    type: 'oak',
    color: '#C19A6B',
    hardness: 'hard',
    grainPattern: 'Prominent, open grain',
    bestUseCase: ['furniture', 'flooring', 'cabinets'],
    averageCostPerBoardFoot: 6.5,
  },
  {
    type: 'walnut',
    color: '#5C4033',
    hardness: 'hard',
    grainPattern: 'Straight, sometimes wavy',
    bestUseCase: ['fine furniture', 'gunstocks', 'decorative items'],
    averageCostPerBoardFoot: 12.0,
  },
  {
    type: 'maple',
    color: '#D7C9AA',
    hardness: 'hard',
    grainPattern: 'Fine, even grain',
    bestUseCase: ['cutting boards', 'flooring', 'musical instruments'],
    averageCostPerBoardFoot: 7.5,
  },
  {
    type: 'cherry',
    color: '#C95A49',
    hardness: 'medium',
    grainPattern: 'Fine, straight grain',
    bestUseCase: ['fine furniture', 'cabinets', 'decorative items'],
    averageCostPerBoardFoot: 8.5,
  },
  {
    type: 'pine',
    color: '#E4D5B7',
    hardness: 'soft',
    grainPattern: 'Straight, pronounced grain',
    bestUseCase: ['construction', 'rustic furniture', 'crafts'],
    averageCostPerBoardFoot: 3.5,
  },
  {
    type: 'mahogany',
    color: '#420D09',
    hardness: 'medium',
    grainPattern: 'Interlocked, ribbon-like',
    bestUseCase: ['fine furniture', 'boats', 'musical instruments'],
    averageCostPerBoardFoot: 15.0,
  },
  {
    type: 'birch',
    color: '#F4E4C1',
    hardness: 'hard',
    grainPattern: 'Fine, even grain',
    bestUseCase: ['plywood', 'furniture', 'cabinetry'],
    averageCostPerBoardFoot: 5.5,
  },
  {
    type: 'cedar',
    color: '#C77F54',
    hardness: 'soft',
    grainPattern: 'Straight, fine grain',
    bestUseCase: ['outdoor furniture', 'decking', 'closet lining'],
    averageCostPerBoardFoot: 4.5,
  },
];

const fasteningTypes = [
  {
    type: 'screw',
    description: 'General purpose wood screws for strong connections',
    strength: 'high',
    bestUseCase: ['general assembly', 'furniture', 'cabinetry'],
    sizes: ['#6', '#8', '#10', '#12'],
    lengths: [0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0],
  },
  {
    type: 'nail',
    description: 'Quick fastening for lighter duty applications',
    strength: 'medium',
    bestUseCase: ['framing', 'trim', 'light assembly'],
    sizes: ['4d', '6d', '8d', '10d', '16d'],
    lengths: [1.5, 2.0, 2.5, 3.0, 3.5],
  },
  {
    type: 'glue',
    description: 'Wood glue for strong, permanent bonds',
    strength: 'very-high',
    bestUseCase: ['edge joining', 'lamination', 'general assembly'],
    dryingTime: '24 hours',
  },
  {
    type: 'dovetail',
    description: 'Traditional interlocking joint for superior strength',
    strength: 'very-high',
    bestUseCase: ['drawer construction', 'fine furniture', 'boxes'],
    skillLevel: 'advanced',
  },
  {
    type: 'mortise-tenon',
    description: 'Classic joint for frame and panel construction',
    strength: 'very-high',
    bestUseCase: ['tables', 'chairs', 'frame construction'],
    skillLevel: 'intermediate',
  },
  {
    type: 'dowel',
    description: 'Simple alignment and reinforcement',
    strength: 'high',
    bestUseCase: ['edge joining', 'frame assembly', 'alignment'],
    sizes: [0.25, 0.375, 0.5, 0.625],
  },
  {
    type: 'biscuit',
    description: 'Oval-shaped wafers for alignment and joining',
    strength: 'high',
    bestUseCase: ['edge joining', 'panel alignment', 'frame assembly'],
    sizes: ['#0', '#10', '#20'],
  },
  {
    type: 'pocket-screw',
    description: 'Hidden fastening method for quick assembly',
    strength: 'high',
    bestUseCase: ['face frames', 'cabinet construction', 'quick assembly'],
    requiresJig: true,
  },
  {
    type: 'brad-nail',
    description: 'Small, thin nails for delicate work',
    strength: 'low',
    bestUseCase: ['trim', 'molding', 'decorative elements'],
    sizes: ['18 gauge', '23 gauge'],
    lengths: [0.625, 0.75, 1.0, 1.25],
  },
  {
    type: 'wood-screw',
    description: 'Coarse thread screws designed specifically for wood',
    strength: 'very-high',
    bestUseCase: ['heavy construction', 'structural joining', 'outdoor projects'],
    sizes: ['#8', '#10', '#12', '#14'],
    lengths: [1.5, 2.0, 2.5, 3.0, 4.0],
  },
];

export const getWoodTypes = (req: Request, res: Response) => {
  res.json(woodTypes);
};

export const getFasteningTypes = (req: Request, res: Response) => {
  res.json(fasteningTypes);
};
