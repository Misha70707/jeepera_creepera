import { create } from 'zustand';
import type { WoodPiece, Fastening, Project } from '../types';
import { v4 as uuidv4 } from 'uuid';

interface StoreState {
  // Current project
  currentProject: Project | null;
  pieces: WoodPiece[];
  fastenings: Fastening[];

  // Selected items
  selectedPiece: string | null;
  selectedFastening: string | null;

  // UI state
  activeView: 'workspace' | 'materials' | 'assembly' | 'export';
  showGrid: boolean;

  // Actions
  createNewProject: (name: string, description?: string) => void;
  loadProject: (project: Project) => void;
  updateProjectInfo: (info: { name?: string; description?: string }) => void;

  addPiece: (piece: Omit<WoodPiece, 'id'>) => void;
  updatePiece: (id: string, updates: Partial<WoodPiece>) => void;
  deletePiece: (id: string) => void;
  selectPiece: (id: string | null) => void;

  addFastening: (fastening: Omit<Fastening, 'id'>) => void;
  updateFastening: (id: string, updates: Partial<Fastening>) => void;
  deleteFastening: (id: string) => void;
  selectFastening: (id: string | null) => void;

  setActiveView: (view: 'workspace' | 'materials' | 'assembly' | 'export') => void;
  toggleGrid: () => void;

  clearProject: () => void;
}

export const useStore = create<StoreState>((set, get) => ({
  // Initial state
  currentProject: null,
  pieces: [],
  fastenings: [],
  selectedPiece: null,
  selectedFastening: null,
  activeView: 'workspace',
  showGrid: true,

  // Actions
  createNewProject: (name, description = '') => {
    const project: Project = {
      id: uuidv4(),
      name,
      description,
      pieces: [],
      fastenings: [],
      createdAt: new Date(),
      updatedAt: new Date(),
      tags: [],
    };
    set({ currentProject: project, pieces: [], fastenings: [] });
  },

  loadProject: (project) => {
    set({
      currentProject: project,
      pieces: project.pieces,
      fastenings: project.fastenings,
      selectedPiece: null,
      selectedFastening: null,
    });
  },

  updateProjectInfo: (info) => {
    const { currentProject } = get();
    if (currentProject) {
      set({
        currentProject: {
          ...currentProject,
          ...info,
          updatedAt: new Date(),
        },
      });
    }
  },

  addPiece: (piece) => {
    const newPiece: WoodPiece = {
      ...piece,
      id: uuidv4(),
    };
    set((state) => ({
      pieces: [...state.pieces, newPiece],
      currentProject: state.currentProject
        ? {
            ...state.currentProject,
            pieces: [...state.pieces, newPiece],
            updatedAt: new Date(),
          }
        : null,
    }));
  },

  updatePiece: (id, updates) => {
    set((state) => {
      const updatedPieces = state.pieces.map((piece) =>
        piece.id === id ? { ...piece, ...updates } : piece
      );
      return {
        pieces: updatedPieces,
        currentProject: state.currentProject
          ? {
              ...state.currentProject,
              pieces: updatedPieces,
              updatedAt: new Date(),
            }
          : null,
      };
    });
  },

  deletePiece: (id) => {
    set((state) => {
      const updatedPieces = state.pieces.filter((piece) => piece.id !== id);
      const updatedFastenings = state.fastenings.filter(
        (f) => !f.connectedPieces.includes(id)
      );
      return {
        pieces: updatedPieces,
        fastenings: updatedFastenings,
        selectedPiece: state.selectedPiece === id ? null : state.selectedPiece,
        currentProject: state.currentProject
          ? {
              ...state.currentProject,
              pieces: updatedPieces,
              fastenings: updatedFastenings,
              updatedAt: new Date(),
            }
          : null,
      };
    });
  },

  selectPiece: (id) => set({ selectedPiece: id, selectedFastening: null }),

  addFastening: (fastening) => {
    const newFastening: Fastening = {
      ...fastening,
      id: uuidv4(),
    };
    set((state) => ({
      fastenings: [...state.fastenings, newFastening],
      currentProject: state.currentProject
        ? {
            ...state.currentProject,
            fastenings: [...state.fastenings, newFastening],
            updatedAt: new Date(),
          }
        : null,
    }));
  },

  updateFastening: (id, updates) => {
    set((state) => {
      const updatedFastenings = state.fastenings.map((fastening) =>
        fastening.id === id ? { ...fastening, ...updates } : fastening
      );
      return {
        fastenings: updatedFastenings,
        currentProject: state.currentProject
          ? {
              ...state.currentProject,
              fastenings: updatedFastenings,
              updatedAt: new Date(),
            }
          : null,
      };
    });
  },

  deleteFastening: (id) => {
    set((state) => {
      const updatedFastenings = state.fastenings.filter((f) => f.id !== id);
      return {
        fastenings: updatedFastenings,
        selectedFastening: state.selectedFastening === id ? null : state.selectedFastening,
        currentProject: state.currentProject
          ? {
              ...state.currentProject,
              fastenings: updatedFastenings,
              updatedAt: new Date(),
            }
          : null,
      };
    });
  },

  selectFastening: (id) => set({ selectedFastening: id, selectedPiece: null }),

  setActiveView: (view) => set({ activeView: view }),

  toggleGrid: () => set((state) => ({ showGrid: !state.showGrid })),

  clearProject: () => set({
    currentProject: null,
    pieces: [],
    fastenings: [],
    selectedPiece: null,
    selectedFastening: null,
  }),
}));
