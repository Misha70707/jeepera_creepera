import { useState, useEffect } from 'react';
import { BookOpen, Clock, Wrench, AlertTriangle, ChevronRight } from 'lucide-react';
import { useStore } from '../hooks/useStore';
import type { AssemblyStep } from '../types';

export function AssemblyView() {
  const currentProject = useStore((state) => state.currentProject);
  const pieces = useStore((state) => state.pieces);
  const fastenings = useStore((state) => state.fastenings);
  const [assemblySteps, setAssemblySteps] = useState<AssemblyStep[]>([]);
  const [selectedStep, setSelectedStep] = useState<number>(0);

  useEffect(() => {
    generateAssemblyGuide();
  }, [pieces, fastenings]);

  const generateAssemblyGuide = () => {
    const steps: AssemblyStep[] = [];

    // Step 1: Prepare all pieces
    steps.push({
      stepNumber: 1,
      title: 'Prepare all wood pieces',
      description:
        'Cut and sand all wood pieces to the specified dimensions. Ensure all edges are smooth and square.',
      pieces: pieces.map((p) => p.id),
      fastenings: [],
      tools: ['table saw', 'miter saw', 'sandpaper', 'measuring tape'],
      estimatedTime: pieces.length * 10,
      safetyNotes: [
        'Always wear safety glasses when cutting',
        'Keep hands away from saw blade',
        'Use push sticks for small pieces',
      ],
    });

    // Group fastenings by connected pieces
    const assemblyGroups = new Map<string, any[]>();
    fastenings.forEach((fastening) => {
      const key = fastening.connectedPieces.sort().join('-');
      if (!assemblyGroups.has(key)) {
        assemblyGroups.set(key, []);
      }
      assemblyGroups.get(key)?.push(fastening);
    });

    // Create steps for each assembly group
    let stepNumber = 2;
    assemblyGroups.forEach((fastenings, key) => {
      const pieceIds = key.split('-');
      const piece1 = pieces.find((p) => p.id === pieceIds[0]);
      const piece2 = pieces.find((p) => p.id === pieceIds[1]);

      if (piece1 && piece2) {
        const tools = fastenings.map((f: any) => {
          switch (f.type) {
            case 'screw':
            case 'wood-screw':
              return 'drill with driver bit';
            case 'nail':
              return 'hammer';
            case 'glue':
              return 'wood glue and clamps';
            case 'dovetail':
              return 'dovetail jig and router';
            case 'mortise-tenon':
              return 'chisel and mallet';
            default:
              return 'appropriate tools';
          }
        });

        steps.push({
          stepNumber: stepNumber++,
          title: `Attach ${piece1.name} to ${piece2.name}`,
          description: `Join these pieces using ${fastenings.map((f: any) => f.type).join(', ')}. Ensure proper alignment before fastening.`,
          pieces: [piece1.id, piece2.id],
          fastenings: fastenings.map((f: any) => f.id),
          tools: [...new Set(tools)],
          estimatedTime: 15,
          safetyNotes: [
            'Ensure pieces are properly aligned',
            'Apply even pressure when fastening',
            'Check for stability after joining',
          ],
        });
      }
    });

    // Final step
    steps.push({
      stepNumber: stepNumber,
      title: 'Final inspection and finishing',
      description:
        'Inspect all joints for stability and proper alignment. Sand any rough areas. Apply your choice of finish (stain, paint, or clear coat) and let dry completely.',
      pieces: pieces.map((p) => p.id),
      fastenings: [],
      tools: ['sandpaper', 'wood finish', 'brushes', 'tack cloth'],
      estimatedTime: 60,
      safetyNotes: [
        'Work in well-ventilated area when applying finishes',
        'Wear appropriate respirator for finishes',
        'Follow manufacturer instructions for drying times',
      ],
    });

    setAssemblySteps(steps);
  };

  const totalTime = assemblySteps.reduce((sum, step) => sum + (step.estimatedTime || 0), 0);

  if (assemblySteps.length === 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">Generating assembly guide...</p>
      </div>
    );
  }

  const currentStep = assemblySteps[selectedStep];

  return (
    <div className="h-full flex">
      {/* Steps list */}
      <div className="w-80 bg-gray-800 border-r border-gray-700 overflow-y-auto scrollbar-thin">
        <div className="p-4 border-b border-gray-700">
          <h2 className="text-xl font-bold text-amber-500 flex items-center gap-2">
            <BookOpen className="w-6 h-6" />
            Assembly Steps
          </h2>
          <p className="text-sm text-gray-400 mt-1 flex items-center gap-2">
            <Clock className="w-4 h-4" />
            Total time: ~{totalTime} minutes
          </p>
        </div>

        <div className="p-2">
          {assemblySteps.map((step, index) => (
            <button
              key={step.stepNumber}
              onClick={() => setSelectedStep(index)}
              className={`w-full text-left p-4 rounded-lg mb-2 transition-colors ${
                selectedStep === index
                  ? 'bg-amber-600 text-white'
                  : 'bg-gray-700 hover:bg-gray-600'
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                    selectedStep === index ? 'bg-white text-amber-600' : 'bg-gray-600'
                  }`}
                >
                  {step.stepNumber}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium truncate">{step.title}</p>
                  <p className="text-xs opacity-70 mt-1 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {step.estimatedTime} min
                  </p>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Step details */}
      <div className="flex-1 overflow-y-auto scrollbar-thin p-6">
        <div className="max-w-3xl mx-auto">
          <div className="mb-6">
            <div className="flex items-center gap-4 mb-2">
              <div className="w-12 h-12 rounded-full bg-amber-600 text-white flex items-center justify-center text-xl font-bold">
                {currentStep.stepNumber}
              </div>
              <div>
                <h1 className="text-3xl font-bold text-amber-500">{currentStep.title}</h1>
                <p className="text-gray-400 flex items-center gap-2 mt-1">
                  <Clock className="w-4 h-4" />
                  Estimated time: {currentStep.estimatedTime} minutes
                </p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div className="card mb-6">
            <h3 className="text-lg font-semibold mb-3">Instructions</h3>
            <p className="text-gray-300 leading-relaxed">{currentStep.description}</p>
          </div>

          {/* Tools needed */}
          <div className="card mb-6">
            <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
              <Wrench className="w-5 h-5 text-amber-500" />
              Tools Needed
            </h3>
            <div className="flex flex-wrap gap-2">
              {currentStep.tools.map((tool, index) => (
                <span
                  key={index}
                  className="px-3 py-1 bg-gray-700 rounded-full text-sm capitalize"
                >
                  {tool}
                </span>
              ))}
            </div>
          </div>

          {/* Safety notes */}
          {currentStep.safetyNotes && currentStep.safetyNotes.length > 0 && (
            <div className="card bg-red-900 bg-opacity-20 border-red-700">
              <h3 className="text-lg font-semibold mb-3 flex items-center gap-2 text-red-400">
                <AlertTriangle className="w-5 h-5" />
                Safety Notes
              </h3>
              <ul className="space-y-2">
                {currentStep.safetyNotes.map((note, index) => (
                  <li key={index} className="flex items-start gap-2 text-gray-300">
                    <ChevronRight className="w-4 h-4 text-red-400 flex-shrink-0 mt-1" />
                    <span>{note}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Navigation */}
          <div className="flex gap-4 mt-8">
            <button
              onClick={() => setSelectedStep(Math.max(0, selectedStep - 1))}
              disabled={selectedStep === 0}
              className="btn btn-secondary flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous Step
            </button>
            <button
              onClick={() =>
                setSelectedStep(Math.min(assemblySteps.length - 1, selectedStep + 1))
              }
              disabled={selectedStep === assemblySteps.length - 1}
              className="btn btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next Step
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
