import { useState } from 'react';
import {
  Box,
  Ruler,
  Wrench,
  Plus,
  Trash2,
  Edit,
  Layers,
  Settings,
  ChevronRight,
  ChevronDown,
} from 'lucide-react';
import { useStore } from '../hooks/useStore';
import type { WoodType, FasteningType } from '../types';

export function Sidebar() {
  const pieces = useStore((state) => state.pieces);
  const fastenings = useStore((state) => state.fastenings);
  const selectedPiece = useStore((state) => state.selectedPiece);
  const selectedFastening = useStore((state) => state.selectedFastening);
  const selectPiece = useStore((state) => state.selectPiece);
  const deletePiece = useStore((state) => state.deletePiece);
  const deleteFastening = useStore((state) => state.deleteFastening);

  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    pieces: true,
    fastenings: true,
  });

  const toggleSection = (section: string) => {
    setExpandedSections((prev) => ({ ...prev, [section]: !prev[section] }));
  };

  return (
    <div className="w-80 bg-gray-800 border-r border-gray-700 flex flex-col h-full overflow-hidden">
      <div className="p-4 border-b border-gray-700">
        <h2 className="text-xl font-bold text-amber-500 flex items-center gap-2">
          <Layers className="w-6 h-6" />
          Project Elements
        </h2>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin">
        {/* Wood Pieces Section */}
        <div className="border-b border-gray-700">
          <button
            onClick={() => toggleSection('pieces')}
            className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-700 transition-colors"
          >
            <div className="flex items-center gap-2">
              <Box className="w-5 h-5 text-amber-500" />
              <span className="font-semibold">Wood Pieces ({pieces.length})</span>
            </div>
            {expandedSections.pieces ? (
              <ChevronDown className="w-4 h-4" />
            ) : (
              <ChevronRight className="w-4 h-4" />
            )}
          </button>

          {expandedSections.pieces && (
            <div className="px-2 py-2 space-y-1">
              {pieces.length === 0 ? (
                <p className="text-gray-500 text-sm px-4 py-2">No pieces yet</p>
              ) : (
                pieces.map((piece) => (
                  <div
                    key={piece.id}
                    className={`px-3 py-2 rounded-lg cursor-pointer transition-colors ${
                      selectedPiece === piece.id
                        ? 'bg-amber-600 text-white'
                        : 'hover:bg-gray-700'
                    }`}
                    onClick={() => selectPiece(piece.id)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <p className="font-medium text-sm">{piece.name}</p>
                        <p className="text-xs opacity-70">
                          {piece.woodType} • {piece.dimensions.length}" × {piece.dimensions.width}" × {piece.dimensions.thickness}"
                        </p>
                      </div>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          if (
                            window.confirm(`Delete piece "${piece.name}"?`)
                          ) {
                            deletePiece(piece.id);
                          }
                        }}
                        className="p-1 hover:bg-red-600 rounded transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </div>

        {/* Fastenings Section */}
        <div className="border-b border-gray-700">
          <button
            onClick={() => toggleSection('fastenings')}
            className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-700 transition-colors"
          >
            <div className="flex items-center gap-2">
              <Wrench className="w-5 h-5 text-amber-500" />
              <span className="font-semibold">Fastenings ({fastenings.length})</span>
            </div>
            {expandedSections.fastenings ? (
              <ChevronDown className="w-4 h-4" />
            ) : (
              <ChevronRight className="w-4 h-4" />
            )}
          </button>

          {expandedSections.fastenings && (
            <div className="px-2 py-2 space-y-1">
              {fastenings.length === 0 ? (
                <p className="text-gray-500 text-sm px-4 py-2">No fastenings yet</p>
              ) : (
                fastenings.map((fastening) => (
                  <div
                    key={fastening.id}
                    className={`px-3 py-2 rounded-lg cursor-pointer transition-colors ${
                      selectedFastening === fastening.id
                        ? 'bg-amber-600 text-white'
                        : 'hover:bg-gray-700'
                    }`}
                    onClick={() => useStore.getState().selectFastening(fastening.id)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <p className="font-medium text-sm capitalize">{fastening.type.replace('-', ' ')}</p>
                        <p className="text-xs opacity-70">
                          Strength: {fastening.strength}
                        </p>
                      </div>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          if (
                            window.confirm(`Delete this ${fastening.type}?`)
                          ) {
                            deleteFastening(fastening.id);
                          }
                        }}
                        className="p-1 hover:bg-red-600 rounded transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
