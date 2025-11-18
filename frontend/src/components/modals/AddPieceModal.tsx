import { useState } from 'react';
import { X } from 'lucide-react';
import { useStore } from '../../hooks/useStore';
import type { WoodType } from '../../types';

interface AddPieceModalProps {
  onClose: () => void;
}

const woodTypes: { value: WoodType; label: string; description: string }[] = [
  { value: 'oak', label: 'Oak', description: 'Hard, durable, prominent grain' },
  { value: 'walnut', label: 'Walnut', description: 'Fine furniture, rich dark color' },
  { value: 'maple', label: 'Maple', description: 'Hard, light color, fine grain' },
  { value: 'cherry', label: 'Cherry', description: 'Medium hardness, reddish tone' },
  { value: 'pine', label: 'Pine', description: 'Soft, affordable, rustic' },
  { value: 'mahogany', label: 'Mahogany', description: 'Premium, deep red-brown' },
  { value: 'birch', label: 'Birch', description: 'Hard, light color, fine grain' },
  { value: 'cedar', label: 'Cedar', description: 'Aromatic, outdoor projects' },
];

export function AddPieceModal({ onClose }: AddPieceModalProps) {
  const addPiece = useStore((state) => state.addPiece);

  const [formData, setFormData] = useState({
    name: '',
    woodType: 'oak' as WoodType,
    length: 12,
    width: 6,
    thickness: 1,
    posX: 0,
    posY: 0.5,
    posZ: 0,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    addPiece({
      name: formData.name || `${formData.woodType} piece`,
      woodType: formData.woodType,
      dimensions: {
        length: formData.length,
        width: formData.width,
        thickness: formData.thickness,
      },
      position: {
        x: formData.posX,
        y: formData.posY,
        z: formData.posZ,
      },
      rotation: {
        x: 0,
        y: 0,
        z: 0,
      },
    });

    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-gray-800 rounded-xl shadow-2xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-700 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-amber-500">Add Wood Piece</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Name */}
          <div>
            <label className="label">Piece Name</label>
            <input
              type="text"
              className="input"
              placeholder="e.g., Table Top, Leg 1, Side Panel"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />
          </div>

          {/* Wood Type */}
          <div>
            <label className="label">Wood Type</label>
            <select
              className="input"
              value={formData.woodType}
              onChange={(e) => setFormData({ ...formData, woodType: e.target.value as WoodType })}
            >
              {woodTypes.map((wood) => (
                <option key={wood.value} value={wood.value}>
                  {wood.label} - {wood.description}
                </option>
              ))}
            </select>
          </div>

          {/* Dimensions */}
          <div>
            <label className="label">Dimensions (inches)</label>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="text-xs text-gray-400 mb-1 block">Length</label>
                <input
                  type="number"
                  className="input"
                  min="0.1"
                  step="0.1"
                  value={formData.length}
                  onChange={(e) =>
                    setFormData({ ...formData, length: parseFloat(e.target.value) })
                  }
                  required
                />
              </div>
              <div>
                <label className="text-xs text-gray-400 mb-1 block">Width</label>
                <input
                  type="number"
                  className="input"
                  min="0.1"
                  step="0.1"
                  value={formData.width}
                  onChange={(e) =>
                    setFormData({ ...formData, width: parseFloat(e.target.value) })
                  }
                  required
                />
              </div>
              <div>
                <label className="text-xs text-gray-400 mb-1 block">Thickness</label>
                <input
                  type="number"
                  className="input"
                  min="0.1"
                  step="0.1"
                  value={formData.thickness}
                  onChange={(e) =>
                    setFormData({ ...formData, thickness: parseFloat(e.target.value) })
                  }
                  required
                />
              </div>
            </div>
          </div>

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

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <button type="submit" className="btn btn-primary flex-1">
              Add Piece
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
