import { Download, FileText, Image, Code } from 'lucide-react';
import { useStore } from '../hooks/useStore';

export function ExportView() {
  const currentProject = useStore((state) => state.currentProject);
  const pieces = useStore((state) => state.pieces);
  const fastenings = useStore((state) => state.fastenings);

  const exportAsJSON = () => {
    if (!currentProject) return;

    const data = JSON.stringify(currentProject, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentProject.name.replace(/\s+/g, '-')}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportAsCSV = () => {
    if (!currentProject) return;

    let csv = 'Type,Name,Material,Length,Width,Thickness,X,Y,Z\n';

    pieces.forEach((piece) => {
      csv += `Piece,"${piece.name}",${piece.woodType},${piece.dimensions.length},${piece.dimensions.width},${piece.dimensions.thickness},${piece.position.x},${piece.position.y},${piece.position.z}\n`;
    });

    fastenings.forEach((fastening) => {
      csv += `Fastening,${fastening.type},N/A,N/A,N/A,N/A,${fastening.position.x},${fastening.position.y},${fastening.position.z}\n`;
    });

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentProject.name.replace(/\s+/g, '-')}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportAsSVG = () => {
    if (!currentProject) return;

    // Simple 2D top-down view SVG
    const width = 800;
    const height = 600;
    const scale = 20;

    let svg = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">\n`;
    svg += `  <rect width="${width}" height="${height}" fill="#f5f5f5"/>\n`;
    svg += `  <g transform="translate(${width / 2}, ${height / 2})">\n`;

    pieces.forEach((piece) => {
      const x = piece.position.x * scale - (piece.dimensions.length * scale) / 2;
      const y = piece.position.z * scale - (piece.dimensions.width * scale) / 2;
      const w = piece.dimensions.length * scale;
      const h = piece.dimensions.width * scale;

      svg += `    <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#8B4513" stroke="#000" stroke-width="1"/>\n`;
      svg += `    <text x="${x + w / 2}" y="${y + h / 2}" text-anchor="middle" dominant-baseline="middle" font-size="10" fill="#fff">${piece.name}</text>\n`;
    });

    svg += `  </g>\n`;
    svg += `</svg>`;

    const blob = new Blob([svg], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentProject.name.replace(/\s+/g, '-')}-blueprint.svg`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportCuttingList = () => {
    if (!currentProject) return;

    let text = `CUTTING LIST - ${currentProject.name}\n`;
    text += `Generated: ${new Date().toLocaleString()}\n\n`;
    text += `${'Qty'.padEnd(6)}${'Material'.padEnd(12)}${'Length'.padEnd(10)}${'Width'.padEnd(10)}${'Thickness'.padEnd(12)}Name\n`;
    text += `${'='.repeat(80)}\n`;

    // Group pieces
    const grouped = new Map<string, any>();
    pieces.forEach((piece) => {
      const key = `${piece.woodType}-${piece.dimensions.length}-${piece.dimensions.width}-${piece.dimensions.thickness}`;
      if (!grouped.has(key)) {
        grouped.set(key, {
          woodType: piece.woodType,
          dimensions: piece.dimensions,
          names: [],
          count: 0,
        });
      }
      const group = grouped.get(key);
      group.names.push(piece.name);
      group.count += 1;
    });

    grouped.forEach((group) => {
      const qty = group.count.toString().padEnd(6);
      const material = group.woodType.padEnd(12);
      const length = `${group.dimensions.length}"`.padEnd(10);
      const width = `${group.dimensions.width}"`.padEnd(10);
      const thickness = `${group.dimensions.thickness}"`.padEnd(12);
      const names = group.names.join(', ');

      text += `${qty}${material}${length}${width}${thickness}${names}\n`;
    });

    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentProject.name.replace(/\s+/g, '-')}-cutting-list.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (!currentProject) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">No project loaded</p>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto scrollbar-thin p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-amber-500 flex items-center gap-3">
            <Download className="w-8 h-8" />
            Export Project
          </h1>
          <p className="text-gray-400 mt-2">
            Export your project in various formats for sharing, documentation, or manufacturing
          </p>
        </div>

        {/* Export options */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* JSON Export */}
          <button onClick={exportAsJSON} className="card hover:bg-gray-700 transition-colors text-left">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-amber-600 rounded-lg flex items-center justify-center flex-shrink-0">
                <Code className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-amber-400">JSON Data</h3>
                <p className="text-sm text-gray-400 mt-1">
                  Export complete project data in JSON format. Useful for backup and sharing.
                </p>
                <div className="mt-3">
                  <span className="text-xs bg-gray-700 px-2 py-1 rounded">.json</span>
                </div>
              </div>
            </div>
          </button>

          {/* CSV Export */}
          <button onClick={exportAsCSV} className="card hover:bg-gray-700 transition-colors text-left">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-green-600 rounded-lg flex items-center justify-center flex-shrink-0">
                <FileText className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-green-400">CSV Spreadsheet</h3>
                <p className="text-sm text-gray-400 mt-1">
                  Export project data as CSV for use in Excel or other spreadsheet applications.
                </p>
                <div className="mt-3">
                  <span className="text-xs bg-gray-700 px-2 py-1 rounded">.csv</span>
                </div>
              </div>
            </div>
          </button>

          {/* SVG Blueprint */}
          <button onClick={exportAsSVG} className="card hover:bg-gray-700 transition-colors text-left">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
                <Image className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-blue-400">SVG Blueprint</h3>
                <p className="text-sm text-gray-400 mt-1">
                  Generate a 2D top-down blueprint view as scalable vector graphics.
                </p>
                <div className="mt-3">
                  <span className="text-xs bg-gray-700 px-2 py-1 rounded">.svg</span>
                </div>
              </div>
            </div>
          </button>

          {/* Cutting List */}
          <button
            onClick={exportCuttingList}
            className="card hover:bg-gray-700 transition-colors text-left"
          >
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
                <FileText className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-purple-400">Cutting List</h3>
                <p className="text-sm text-gray-400 mt-1">
                  Generate a formatted cutting list with all dimensions and quantities.
                </p>
                <div className="mt-3">
                  <span className="text-xs bg-gray-700 px-2 py-1 rounded">.txt</span>
                </div>
              </div>
            </div>
          </button>
        </div>

        {/* Project info */}
        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Project Information</h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-400">Project Name:</span>
              <span className="font-medium">{currentProject.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Wood Pieces:</span>
              <span className="font-medium">{pieces.length}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Fastenings:</span>
              <span className="font-medium">{fastenings.length}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Created:</span>
              <span className="font-medium">
                {new Date(currentProject.createdAt).toLocaleDateString()}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Last Modified:</span>
              <span className="font-medium">
                {new Date(currentProject.updatedAt).toLocaleDateString()}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
