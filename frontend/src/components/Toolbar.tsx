import { useState } from 'react';
import {
  Plus,
  Save,
  FolderOpen,
  Download,
  Grid3x3,
  FileText,
  Scissors,
  BookOpen,
  ShieldAlert,
  Home,
} from 'lucide-react';
import { useStore } from '../hooks/useStore';
import { AddPieceModal } from './modals/AddPieceModal';
import { AddFasteningModal } from './modals/AddFasteningModal';

export function Toolbar() {
  const [showAddPieceModal, setShowAddPieceModal] = useState(false);
  const [showAddFasteningModal, setShowAddFasteningModal] = useState(false);
  const currentProject = useStore((state) => state.currentProject);
  const showGrid = useStore((state) => state.showGrid);
  const toggleGrid = useStore((state) => state.toggleGrid);
  const setActiveView = useStore((state) => state.setActiveView);
  const activeView = useStore((state) => state.activeView);

  return (
    <>
      <div className="h-16 bg-gray-800 border-b border-gray-700 flex items-center justify-between px-4">
        {/* Left section */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveView('workspace')}
            className={`btn ${
              activeView === 'workspace' ? 'btn-primary' : 'btn-secondary'
            } flex items-center gap-2`}
          >
            <Home className="w-4 h-4" />
            Workspace
          </button>
        </div>

        {/* Middle section - Action buttons */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowAddPieceModal(true)}
            className="btn btn-primary flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Add Piece
          </button>

          <button
            onClick={() => setShowAddFasteningModal(true)}
            className="btn btn-primary flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            Add Fastening
          </button>

          <div className="w-px h-8 bg-gray-700 mx-2" />

          <button
            onClick={() => setActiveView('materials')}
            className={`btn ${
              activeView === 'materials' ? 'btn-primary' : 'btn-secondary'
            } flex items-center gap-2`}
          >
            <FileText className="w-4 h-4" />
            Materials
          </button>

          <button
            onClick={() => setActiveView('assembly')}
            className={`btn ${
              activeView === 'assembly' ? 'btn-primary' : 'btn-secondary'
            } flex items-center gap-2`}
          >
            <BookOpen className="w-4 h-4" />
            Assembly
          </button>

          <button
            onClick={() => setActiveView('export')}
            className={`btn ${
              activeView === 'export' ? 'btn-primary' : 'btn-secondary'
            } flex items-center gap-2`}
          >
            <Download className="w-4 h-4" />
            Export
          </button>
        </div>

        {/* Right section */}
        <div className="flex items-center gap-2">
          <button
            onClick={toggleGrid}
            className={`btn ${showGrid ? 'btn-primary' : 'btn-secondary'} flex items-center gap-2`}
          >
            <Grid3x3 className="w-4 h-4" />
            Grid
          </button>

          <div className="w-px h-8 bg-gray-700 mx-2" />

          <div className="text-sm text-gray-400">
            {currentProject ? (
              <span className="text-gray-200 font-medium">{currentProject.name}</span>
            ) : (
              'No project loaded'
            )}
          </div>
        </div>
      </div>

      {/* Modals */}
      {showAddPieceModal && <AddPieceModal onClose={() => setShowAddPieceModal(false)} />}
      {showAddFasteningModal && (
        <AddFasteningModal onClose={() => setShowAddFasteningModal(false)} />
      )}
    </>
  );
}
