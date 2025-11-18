import { Canvas } from '@react-three/fiber';
import { OrbitControls, Grid, PerspectiveCamera, Sky } from '@react-three/drei';
import { WoodPieceComponent } from './WoodPieceComponent';
import { FasteningComponent } from './FasteningComponent';
import { useStore } from '../hooks/useStore';

export function Scene3D() {
  const pieces = useStore((state) => state.pieces);
  const fastenings = useStore((state) => state.fastenings);
  const showGrid = useStore((state) => state.showGrid);

  return (
    <div className="w-full h-full bg-gradient-to-b from-blue-200 to-gray-100">
      <Canvas shadows>
        {/* Camera */}
        <PerspectiveCamera makeDefault position={[10, 10, 10]} fov={50} />

        {/* Lighting */}
        <ambientLight intensity={0.5} />
        <directionalLight
          position={[10, 20, 10]}
          intensity={1}
          castShadow
          shadow-mapSize-width={2048}
          shadow-mapSize-height={2048}
          shadow-camera-far={50}
          shadow-camera-left={-20}
          shadow-camera-right={20}
          shadow-camera-top={20}
          shadow-camera-bottom={-20}
        />
        <pointLight position={[-10, 10, -10]} intensity={0.3} />
        <hemisphereLight args={['#87CEEB', '#8B4513', 0.3]} />

        {/* Sky background */}
        <Sky sunPosition={[100, 20, 100]} />

        {/* Grid */}
        {showGrid && (
          <Grid
            args={[20, 20]}
            cellSize={1}
            cellThickness={0.5}
            cellColor="#888888"
            sectionSize={5}
            sectionThickness={1}
            sectionColor="#444444"
            fadeDistance={30}
            fadeStrength={1}
            infiniteGrid
          />
        )}

        {/* Ground plane for shadows */}
        <mesh receiveShadow rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]}>
          <planeGeometry args={[100, 100]} />
          <shadowMaterial opacity={0.3} />
        </mesh>

        {/* Wood pieces */}
        {pieces.map((piece) => (
          <WoodPieceComponent key={piece.id} piece={piece} />
        ))}

        {/* Fastenings */}
        {fastenings.map((fastening) => (
          <FasteningComponent key={fastening.id} fastening={fastening} />
        ))}

        {/* Controls */}
        <OrbitControls
          enableDamping
          dampingFactor={0.05}
          minDistance={2}
          maxDistance={50}
          maxPolarAngle={Math.PI / 2}
        />
      </Canvas>
    </div>
  );
}
