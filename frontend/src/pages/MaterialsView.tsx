import { useState, useEffect } from 'react';
import { FileText, Download, DollarSign, Package } from 'lucide-react';
import { useStore } from '../hooks/useStore';
import type { MaterialList } from '../types';

export function MaterialsView() {
  const currentProject = useStore((state) => state.currentProject);
  const pieces = useStore((state) => state.pieces);
  const fastenings = useStore((state) => state.fastenings);
  const [materialList, setMaterialList] = useState<MaterialList | null>(null);

  useEffect(() => {
    generateMaterialList();
  }, [pieces, fastenings]);

  const generateMaterialList = () => {
    // Group pieces by wood type and dimensions
    const woodMap = new Map<string, any>();
    pieces.forEach((piece) => {
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
    fastenings.forEach((fastening) => {
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

    setMaterialList({
      wood: Array.from(woodMap.values()),
      fastenings: Array.from(fasteningMap.values()),
    });
  };

  const exportMaterialList = () => {
    if (!materialList) return;

    let text = `Material List - ${currentProject?.name || 'Project'}\n`;
    text += `Generated: ${new Date().toLocaleString()}\n\n`;

    text += '=== WOOD MATERIALS ===\n\n';
    materialList.wood.forEach((item, index) => {
      text += `${index + 1}. ${item.woodType.toUpperCase()}\n`;
      text += `   Dimensions: ${item.dimensions.length}" × ${item.dimensions.width}" × ${item.dimensions.thickness}"\n`;
      text += `   Quantity: ${item.quantity}\n\n`;
    });

    text += '\n=== FASTENINGS ===\n\n';
    materialList.fastenings.forEach((item, index) => {
      text += `${index + 1}. ${item.type.toUpperCase().replace('-', ' ')}\n`;
      if (item.specifications.size) text += `   Size: ${item.specifications.size}\n`;
      if (item.specifications.length) text += `   Length: ${item.specifications.length}"\n`;
      text += `   Quantity: ${item.quantity}\n\n`;
    });

    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `material-list-${currentProject?.name || 'project'}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (!materialList) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">Generating material list...</p>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto scrollbar-thin p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-amber-500 flex items-center gap-3">
              <FileText className="w-8 h-8" />
              Material List
            </h1>
            <p className="text-gray-400 mt-2">
              Complete list of materials needed for your project
            </p>
          </div>
          <button onClick={exportMaterialList} className="btn btn-primary flex items-center gap-2">
            <Download className="w-4 h-4" />
            Export List
          </button>
        </div>

        {/* Wood Materials */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <Package className="w-6 h-6 text-amber-500" />
            <h2 className="text-xl font-bold">Wood Materials</h2>
          </div>

          {materialList.wood.length === 0 ? (
            <p className="text-gray-500">No wood pieces in project</p>
          ) : (
            <div className="space-y-4">
              {materialList.wood.map((item, index) => (
                <div
                  key={index}
                  className="bg-gray-700 rounded-lg p-4 border border-gray-600"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold text-lg capitalize text-amber-400">
                        {item.woodType}
                      </h3>
                      <p className="text-gray-300 mt-1">
                        Dimensions: {item.dimensions.length}" × {item.dimensions.width}" ×{' '}
                        {item.dimensions.thickness}"
                      </p>
                      <p className="text-gray-400 text-sm mt-1">
                        Volume per piece:{' '}
                        {(
                          (item.dimensions.length *
                            item.dimensions.width *
                            item.dimensions.thickness) /
                          144
                        ).toFixed(2)}{' '}
                        board feet
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-amber-500">×{item.quantity}</p>
                      <p className="text-sm text-gray-400">pieces</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Fastenings */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <Package className="w-6 h-6 text-amber-500" />
            <h2 className="text-xl font-bold">Fastenings & Hardware</h2>
          </div>

          {materialList.fastenings.length === 0 ? (
            <p className="text-gray-500">No fastenings in project</p>
          ) : (
            <div className="space-y-4">
              {materialList.fastenings.map((item, index) => (
                <div
                  key={index}
                  className="bg-gray-700 rounded-lg p-4 border border-gray-600"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold text-lg capitalize text-amber-400">
                        {item.type.replace('-', ' ')}
                      </h3>
                      <div className="text-gray-300 mt-1 space-y-1">
                        {item.specifications.size && (
                          <p className="text-sm">Size: {item.specifications.size}</p>
                        )}
                        {item.specifications.length && (
                          <p className="text-sm">Length: {item.specifications.length}"</p>
                        )}
                        {item.specifications.diameter && (
                          <p className="text-sm">
                            Diameter: {item.specifications.diameter}"
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-amber-500">×{item.quantity}</p>
                      <p className="text-sm text-gray-400">units</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Summary */}
        <div className="card bg-gradient-to-r from-amber-900 to-gray-800">
          <h3 className="text-xl font-bold mb-4">Summary</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-gray-300 text-sm">Total Wood Types</p>
              <p className="text-2xl font-bold text-amber-400">
                {materialList.wood.length}
              </p>
            </div>
            <div>
              <p className="text-gray-300 text-sm">Total Fastening Types</p>
              <p className="text-2xl font-bold text-amber-400">
                {materialList.fastenings.length}
              </p>
            </div>
            <div>
              <p className="text-gray-300 text-sm">Total Wood Pieces</p>
              <p className="text-2xl font-bold text-amber-400">
                {materialList.wood.reduce((sum, item) => sum + item.quantity, 0)}
              </p>
            </div>
            <div>
              <p className="text-gray-300 text-sm">Total Fastenings</p>
              <p className="text-2xl font-bold text-amber-400">
                {materialList.fastenings.reduce((sum, item) => sum + item.quantity, 0)}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
