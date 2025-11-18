import { useState } from 'react';
import { X } from 'lucide-react';
import { useStore } from '../../hooks/useStore';
import type { FasteningType } from '../../types';

interface AddFasteningModalProps {
  onClose: () => void;
}

const fasteningTypes: {
  value: FasteningType;
  label: string;
  description: string;
  strength: 'low' | 'medium' | 'high' | 'very-high';
}[] = [
  {
    value: 'screw',
    label: 'Wood Screw',
    description: 'General purpose, strong connection',
    strength: 'high',
  },
  {
    value: 'nail',
    label: 'Nail',
    description: 'Quick fastening, lighter duty',
    strength: 'medium',
  },
  {
    value: 'glue',
    label: 'Wood Glue',
    description: 'Permanent bond, very strong',
    strength: 'very-high',
  },
  {
    value: 'dovetail',
    label: 'Dovetail Joint',
    description: 'Traditional, superior strength',
    strength: 'very-high',
  },
  {
    value: 'mortise-tenon',
    label: 'Mortise & Tenon',
    description: 'Classic frame construction',
    strength: 'very-high',
  },
  {
    value: 'dowel',
    label: 'Dowel',
    description: 'Alignment and reinforcement',
    strength: 'high',
  },
  {
    value: 'biscuit',
    label: 'Biscuit Joint',
    description: 'Edge joining and alignment',
    strength: 'high',
  },
  {
    value: 'pocket-screw',
    label: 'Pocket Screw',
    description: 'Hidden fastening, quick assembly',
    strength: 'high',
  },
  {
    value: 'brad-nail',
    label: 'Brad Nail',
    description: 'Delicate trim and molding',
    strength: 'low',
  },
];

export function AddFasteningModal({ onClose }: AddFasteningModalProps) {
  const addFastening = useStore((state) => state.addFastening);
  const pieces = useStore((state) => state.pieces);

  const [formData, setFormData] = useState({
    type: 'screw' as FasteningType,
    piece1: '',
    piece2: '',
    posX: 0,
    posY: 0.5,
    posZ: 0,
    size: '#8',
    length: 1.5,
    diameter: 0.164,
    quantity: 1,
  });

  const selectedType = fasteningTypes.find((t) => t.value === formData.type);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.piece1 || !formData.piece2) {
      alert('Please select two pieces to connect');
      return;
    }

    if (formData.piece1 === formData.piece2) {
      alert('Please select two different pieces');
      return;
    }

    addFastening({
      type: formData.type,
      position: {
        x: formData.posX,
        y: formData.posY,
        z: formData.posZ,
      },
      connectedPieces: [formData.piece1, formData.piece2],
      specifications: {
        size: formData.size,
        length: formData.length,
        diameter: formData.diameter,
        quantity: formData.quantity,
      },
      strength: selectedType?.strength || 'medium',
    });

    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-gray-800 rounded-xl shadow-2xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-700 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-amber-500">Add Fastening</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Fastening Type */}
          <div>
            <label className="label">Fastening Type</label>
            <select
              className="input"
              value={formData.type}
              onChange={(e) =>
                setFormData({ ...formData, type: e.target.value as FasteningType })
              }
            >
              {fasteningTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label} - {type.description}
                </option>
              ))}
            </select>
            {selectedType && (
              <p className="mt-2 text-sm text-gray-400">
                <span className="font-semibold">Strength:</span>{' '}
                <span className="capitalize">{selectedType.strength.replace('-', ' ')}</span>
              </p>
            )}
          </div>

          {/* Connected Pieces */}
          {pieces.length < 2 ? (
            <div className="bg-yellow-900 border border-yellow-700 rounded-lg p-4">
              <p className="text-yellow-200">
                You need at least 2 wood pieces to add a fastening. Please add more pieces first.
              </p>
            </div>
          ) : (
            <>
              <div>
                <label className="label">Connect Pieces</label>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">First Piece</label>
                    <select
                      className="input"
                      value={formData.piece1}
                      onChange={(e) => setFormData({ ...formData, piece1: e.target.value })}
                      required
                    >
                      <option value="">Select piece...</option>
                      {pieces.map((piece) => (
                        <option key={piece.id} value={piece.id}>
                          {piece.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Second Piece</label>
                    <select
                      className="input"
                      value={formData.piece2}
                      onChange={(e) => setFormData({ ...formData, piece2: e.target.value })}
                      required
                    >
                      <option value="">Select piece...</option>
                      {pieces.map((piece) => (
                        <option key={piece.id} value={piece.id}>
                          {piece.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* Specifications */}
              {(formData.type === 'screw' || formData.type === 'wood-screw' || formData.type === 'nail') && (
                <div>
                  <label className="label">Specifications</label>
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <label className="text-xs text-gray-400 mb-1 block">Size</label>
                      <input
                        type="text"
                        className="input"
                        value={formData.size}
                        onChange={(e) => setFormData({ ...formData, size: e.target.value })}
                        placeholder="#8"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-gray-400 mb-1 block">Length (in)</label>
                      <input
                        type="number"
                        className="input"
                        min="0.1"
                        step="0.125"
                        value={formData.length}
                        onChange={(e) =>
                          setFormData({ ...formData, length: parseFloat(e.target.value) })
                        }
                      />
                    </div>
                    <div>
                      <label className="text-xs text-gray-400 mb-1 block">Quantity</label>
                      <input
                        type="number"
                        className="input"
                        min="1"
                        value={formData.quantity}
                        onChange={(e) =>
                          setFormData({ ...formData, quantity: parseInt(e.target.value) })
                        }
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* Position */}
              <div>
                <label className="label">Position (3D coordinates)</label>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">X</label>
                    <input
                      type="number"
                      className="input"
                      step="0.5"
                      value={formData.posX}
                      onChange={(e) =>
                        setFormData({ ...formData, posX: parseFloat(e.target.value) })
                      }
                    />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Y</label>
                    <input
                      type="number"
                      className="input"
                      step="0.5"
                      value={formData.posY}
                      onChange={(e) =>
                        setFormData({ ...formData, posY: parseFloat(e.target.value) })
                      }
                    />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Z</label>
                    <input
                      type="number"
                      className="input"
                      step="0.5"
                      value={formData.posZ}
                      onChange={(e) =>
                        setFormData({ ...formData, posZ: parseFloat(e.target.value) })
                      }
                    />
                  </div>
                </div>
              </div>
            </>
          )}

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <button
              type="submit"
              className="btn btn-primary flex-1"
              disabled={pieces.length < 2}
            >
              Add Fastening
            </button>
            <button type="button" onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
