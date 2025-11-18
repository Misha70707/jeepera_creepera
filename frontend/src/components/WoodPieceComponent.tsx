import { useRef, useState } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { useStore } from '../hooks/useStore';
import type { WoodPiece } from '../types';

interface WoodPieceProps {
  piece: WoodPiece;
}

// Wood colors map
const woodColors: Record<string, string> = {
  oak: '#C19A6B',
  walnut: '#5C4033',
  maple: '#D7C9AA',
  cherry: '#C95A49',
  pine: '#E4D5B7',
  mahogany: '#420D09',
  birch: '#F4E4C1',
  cedar: '#C77F54',
};

export function WoodPieceComponent({ piece }: WoodPieceProps) {
  const meshRef = useRef<THREE.Mesh>(null);
  const [hovered, setHovered] = useState(false);
  const selectedPiece = useStore((state) => state.selectedPiece);
  const selectPiece = useStore((state) => state.selectPiece);
  const updatePiece = useStore((state) => state.updatePiece);

  const isSelected = selectedPiece === piece.id;

  // Subtle animation for selected pieces
  useFrame((state) => {
    if (meshRef.current && isSelected) {
      meshRef.current.position.y = piece.position.y + Math.sin(state.clock.elapsedTime * 2) * 0.05;
    }
  });

  const handleClick = (e: any) => {
    e.stopPropagation();
    selectPiece(piece.id);
  };

  const handlePointerDown = (e: any) => {
    e.stopPropagation();
  };

  const color = piece.color || woodColors[piece.woodType] || '#C19A6B';

  return (
    <group
      position={[piece.position.x, piece.position.y, piece.position.z]}
      rotation={[piece.rotation.x, piece.rotation.y, piece.rotation.z]}
    >
      <mesh
        ref={meshRef}
        castShadow
        receiveShadow
        onClick={handleClick}
        onPointerDown={handlePointerDown}
        onPointerOver={() => setHovered(true)}
        onPointerOut={() => setHovered(false)}
      >
        <boxGeometry
          args={[piece.dimensions.length, piece.dimensions.thickness, piece.dimensions.width]}
        />
        <meshStandardMaterial
          color={color}
          roughness={0.7}
          metalness={0.1}
          emissive={isSelected ? '#ffaa00' : hovered ? '#666666' : '#000000'}
          emissiveIntensity={isSelected ? 0.3 : hovered ? 0.1 : 0}
        />
      </mesh>

      {/* Selection outline */}
      {isSelected && (
        <lineSegments>
          <edgesGeometry
            args={[
              new THREE.BoxGeometry(
                piece.dimensions.length * 1.02,
                piece.dimensions.thickness * 1.02,
                piece.dimensions.width * 1.02
              ),
            ]}
          />
          <lineBasicMaterial color="#ffaa00" linewidth={2} />
        </lineSegments>
      )}

      {/* Hover outline */}
      {hovered && !isSelected && (
        <lineSegments>
          <edgesGeometry
            args={[
              new THREE.BoxGeometry(
                piece.dimensions.length * 1.01,
                piece.dimensions.thickness * 1.01,
                piece.dimensions.width * 1.01
              ),
            ]}
          />
          <lineBasicMaterial color="#ffffff" linewidth={1} transparent opacity={0.5} />
        </lineSegments>
      )}
    </group>
  );
}
