import { useEffect } from 'react';
import { useStore } from './hooks/useStore';
import { Sidebar } from './components/Sidebar';
import { Toolbar } from './components/Toolbar';
import { Scene3D } from './components/Scene3D';
import { MaterialsView } from './pages/MaterialsView';
import { AssemblyView } from './pages/AssemblyView';
import { ExportView } from './pages/ExportView';
import { Hammer } from 'lucide-react';

function App() {
  const activeView = useStore((state) => state.activeView);
  const currentProject = useStore((state) => state.currentProject);
  const createNewProject = useStore((state) => state.createNewProject);

  useEffect(() => {
    // Create a default project on first load
    if (!currentProject) {
      createNewProject('My Woodworking Project', 'A new woodworking project created with WoodCraft Designer');
    }
  }, []);

  const renderMainContent = () => {
    switch (activeView) {
      case 'workspace':
        return (
          <div className="flex-1 flex">
            <Sidebar />
            <div className="flex-1 relative">
              <Scene3D />
              {/* Overlay info */}
              <div className="absolute top-4 left-4 bg-gray-800 bg-opacity-90 rounded-lg p-4 max-w-sm">
                <h3 className="font-bold text-amber-500 mb-2">3D Workspace</h3>
                <ul className="text-sm text-gray-300 space-y-1">
                  <li>• Left click + drag to rotate view</li>
                  <li>• Right click + drag to pan</li>
                  <li>• Scroll to zoom in/out</li>
                  <li>• Click on pieces to select them</li>
                </ul>
              </div>
            </div>
          </div>
        );

      case 'materials':
        return <MaterialsView />;

      case 'assembly':
        return <AssemblyView />;

      case 'export':
        return <ExportView />;

      default:
        return null;
    }
  };

  return (
    <div className="w-screen h-screen flex flex-col bg-gray-900 text-gray-100">
      {/* Header */}
      <header className="h-16 bg-gradient-to-r from-amber-700 to-amber-900 border-b border-amber-600 flex items-center justify-between px-6 shadow-lg">
        <div className="flex items-center gap-3">
          <Hammer className="w-8 h-8 text-white" />
          <div>
            <h1 className="text-2xl font-bold text-white">WoodCraft Designer</h1>
            <p className="text-xs text-amber-200">Professional Woodworking Design Tool</p>
          </div>
        </div>
        <div className="text-sm text-amber-100">
          v1.0.0
        </div>
      </header>

      {/* Toolbar */}
      <Toolbar />

      {/* Main content */}
      <div className="flex-1 overflow-hidden">
        {renderMainContent()}
      </div>

      {/* Footer */}
      <footer className="h-8 bg-gray-800 border-t border-gray-700 flex items-center justify-center text-xs text-gray-500">
        <p>
          WoodCraft Designer - Create, customize, and bring your woodworking projects to life
        </p>
      </footer>
    </div>
  );
}

export default App;
