import { useRef, useState } from 'react';
import * as THREE from 'three';
import { useStore } from '../hooks/useStore';
import type { Fastening } from '../types';

interface FasteningProps {
  fastening: Fastening;
}

export function FasteningComponent({ fastening }: FasteningProps) {
  const meshRef = useRef<THREE.Mesh>(null);
  const [hovered, setHovered] = useState(false);
  const selectedFastening = useStore((state) => state.selectedFastening);
  const selectFastening = useStore((state) => state.selectFastening);

  const isSelected = selectedFastening === fastening.id;

  const handleClick = (e: any) => {
    e.stopPropagation();
    selectFastening(fastening.id);
  };

  // Different visualizations for different fastening types
  const renderFastening = () => {
    switch (fastening.type) {
      case 'screw':
      case 'wood-screw':
      case 'pocket-screw':
        return (
          <>
            {/* Screw shaft */}
            <mesh ref={meshRef} castShadow>
              <cylinderGeometry args={[0.05, 0.05, 0.3, 8]} />
              <meshStandardMaterial color="#888888" metalness={0.8} roughness={0.2} />
            </mesh>
            {/* Screw head */}
            <mesh position={[0, 0.15, 0]} castShadow>
              <cylinderGeometry args={[0.08, 0.08, 0.05, 8]} />
              <meshStandardMaterial color="#888888" metalness={0.8} roughness={0.2} />
            </mesh>
          </>
        );

      case 'nail':
      case 'brad-nail':
        return (
          <>
            {/* Nail shaft */}
            <mesh ref={meshRef} castShadow>
              <cylinderGeometry args={[0.03, 0.03, 0.4, 8]} />
              <meshStandardMaterial color="#999999" metalness={0.7} roughness={0.3} />
            </mesh>
            {/* Nail head */}
            <mesh position={[0, 0.2, 0]} castShadow>
              <cylinderGeometry args={[0.05, 0.05, 0.02, 8]} />
              <meshStandardMaterial color="#999999" metalness={0.7} roughness={0.3} />
            </mesh>
          </>
        );

      case 'dowel':
        return (
          <mesh ref={meshRef} castShadow>
            <cylinderGeometry args={[0.08, 0.08, 0.5, 16]} />
            <meshStandardMaterial color="#D2B48C" roughness={0.8} metalness={0} />
          </mesh>
        );

      case 'biscuit':
        return (
          <mesh ref={meshRef} castShadow>
            <boxGeometry args={[0.5, 0.05, 0.2]} />
            <meshStandardMaterial color="#D2B48C" roughness={0.8} metalness={0} />
          </mesh>
        );

      case 'glue':
        // Visualize glue as a translucent blob
        return (
          <mesh ref={meshRef}>
            <sphereGeometry args={[0.1, 16, 16]} />
            <meshStandardMaterial
              color="#FFEB3B"
              transparent
              opacity={0.6}
              roughness={0.9}
              metalness={0}
            />
          </mesh>
        );

      default:
        // Generic fastening visualization
        return (
          <mesh ref={meshRef} castShadow>
            <sphereGeometry args={[0.1, 16, 16]} />
            <meshStandardMaterial color="#666666" metalness={0.5} roughness={0.5} />
          </mesh>
        );
    }
  };

  return (
    <group
      position={[fastening.position.x, fastening.position.y, fastening.position.z]}
      onClick={handleClick}
      onPointerOver={() => setHovered(true)}
      onPointerOut={() => setHovered(false)}
    >
      {renderFastening()}

      {/* Selection indicator */}
      {isSelected && (
        <mesh>
          <sphereGeometry args={[0.15, 16, 16]} />
          <meshBasicMaterial color="#ffaa00" wireframe />
        </mesh>
      )}

      {/* Hover indicator */}
      {hovered && !isSelected && (
        <mesh>
          <sphereGeometry args={[0.12, 16, 16]} />
          <meshBasicMaterial color="#ffffff" wireframe transparent opacity={0.3} />
        </mesh>
      )}
    </group>
  );
}
