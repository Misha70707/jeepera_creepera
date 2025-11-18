// Wood Types
export type WoodType = 'oak' | 'walnut' | 'maple' | 'cherry' | 'pine' | 'mahogany' | 'birch' | 'cedar';

// Fastening Types
export type FasteningType =
  | 'screw'
  | 'nail'
  | 'glue'
  | 'dovetail'
  | 'mortise-tenon'
  | 'dowel'
  | 'biscuit'
  | 'pocket-screw'
  | 'brad-nail'
  | 'wood-screw';

// Wood Piece Interface
export interface WoodPiece {
  id: string;
  name: string;
  woodType: WoodType;
  dimensions: {
    length: number;
    width: number;
    thickness: number;
  };
  position: {
    x: number;
    y: number;
    z: number;
  };
  rotation: {
    x: number;
    y: number;
    z: number;
  };
  color?: string;
  texture?: string;
}

// Fastening Interface
export interface Fastening {
  id: string;
  type: FasteningType;
  position: {
    x: number;
    y: number;
    z: number;
  };
  connectedPieces: [string, string]; // IDs of two connected pieces
  specifications: {
    size?: string;
    length?: number;
    diameter?: number;
    quantity?: number;
  };
  strength: 'low' | 'medium' | 'high' | 'very-high';
}

// Project Interface
export interface Project {
  id: string;
  name: string;
  description: string;
  pieces: WoodPiece[];
  fastenings: Fastening[];
  createdAt: Date;
  updatedAt: Date;
  thumbnail?: string;
  tags?: string[];
}

// Material List Item
export interface MaterialListItem {
  woodType: WoodType;
  dimensions: {
    length: number;
    width: number;
    thickness: number;
  };
  quantity: number;
  estimatedCost?: number;
}

// Fastening List Item
export interface FasteningListItem {
  type: FasteningType;
  specifications: {
    size?: string;
    length?: number;
    diameter?: number;
  };
  quantity: number;
  estimatedCost?: number;
}

// Complete Material List
export interface MaterialList {
  wood: MaterialListItem[];
  fastenings: FasteningListItem[];
  totalEstimatedCost?: number;
}

// Cutting Plan
export interface CuttingPlan {
  sheet: {
    length: number;
    width: number;
    thickness: number;
    woodType: WoodType;
  };
  cuts: {
    pieceId: string;
    position: {
      x: number;
      y: number;
    };
    dimensions: {
      length: number;
      width: number;
    };
  }[];
  wastePercentage: number;
}

// Assembly Step
export interface AssemblyStep {
  stepNumber: number;
  title: string;
  description: string;
  pieces: string[]; // IDs of pieces involved
  fastenings: string[]; // IDs of fastenings to apply
  imageUrl?: string;
  safetyNotes?: string[];
  tools: string[];
  estimatedTime?: number; // in minutes
}

// Safety Tip
export interface SafetyTip {
  id: string;
  title: string;
  description: string;
  severity: 'info' | 'warning' | 'danger';
  relatedTo?: FasteningType | 'general';
}

// Wood Properties
export interface WoodProperties {
  type: WoodType;
  color: string;
  hardness: 'soft' | 'medium' | 'hard';
  grainPattern: string;
  bestUseCase: string[];
  averageCostPerBoardFoot: number;
}
