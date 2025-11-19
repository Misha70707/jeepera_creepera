import { Request, Response } from 'express';
import type { SafetyTip } from '../../../shared/types/index.js';

const safetyTips: SafetyTip[] = [
  // General Safety
  {
    id: '1',
    title: 'Always Wear Safety Glasses',
    description:
      'Eye protection is essential when working with wood. Flying debris, sawdust, and wood chips can cause serious eye injuries.',
    severity: 'danger',
    relatedTo: 'general',
  },
  {
    id: '2',
    title: 'Use Hearing Protection',
    description:
      'Power tools can produce noise levels that damage hearing. Always wear ear protection when operating loud machinery.',
    severity: 'warning',
    relatedTo: 'general',
  },
  {
    id: '3',
    title: 'Keep Work Area Clean',
    description:
      'A cluttered workspace increases the risk of accidents. Keep your work area clean and organized, and clean up sawdust regularly.',
    severity: 'warning',
    relatedTo: 'general',
  },
  {
    id: '4',
    title: 'Use Dust Collection',
    description:
      'Wood dust can be harmful when inhaled. Use dust collection systems and wear a respirator when necessary.',
    severity: 'warning',
    relatedTo: 'general',
  },
  {
    id: '5',
    title: 'Inspect Tools Before Use',
    description:
      'Always check tools for damage before using them. Damaged tools can cause serious injuries.',
    severity: 'danger',
    relatedTo: 'general',
  },

  // Screw-related
  {
    id: '6',
    title: 'Pre-drill Pilot Holes',
    description:
      'Always pre-drill pilot holes when using screws near the edge of wood to prevent splitting. Use a drill bit slightly smaller than the screw shaft.',
    severity: 'info',
    relatedTo: 'screw',
  },
  {
    id: '7',
    title: 'Use Correct Screwdriver Bit',
    description:
      'Using the wrong bit can strip screw heads. Always use the correct size and type of bit for your screws.',
    severity: 'warning',
    relatedTo: 'screw',
  },
  {
    id: '8',
    title: 'Watch for Over-Tightening',
    description:
      'Over-tightening screws can strip threads or crack wood. Stop when the screw is snug and the pieces are firmly joined.',
    severity: 'info',
    relatedTo: 'screw',
  },

  // Nail-related
  {
    id: '9',
    title: 'Support Work When Nailing',
    description:
      'Always support your work firmly when hammering nails. Never hold a piece in your hand while nailing into it.',
    severity: 'danger',
    relatedTo: 'nail',
  },
  {
    id: '10',
    title: 'Watch for Nail Gun Recoil',
    description:
      'Pneumatic nail guns have significant recoil. Keep firm control and never point the tool at yourself or others.',
    severity: 'danger',
    relatedTo: 'nail',
  },
  {
    id: '11',
    title: 'Set Nails Below Surface',
    description:
      'Use a nail set to drive nail heads slightly below the wood surface for a clean finish and to prevent injury from protruding nails.',
    severity: 'info',
    relatedTo: 'nail',
  },

  // Glue-related
  {
    id: '12',
    title: 'Work in Ventilated Area',
    description:
      'Some wood glues emit fumes. Always work in a well-ventilated area and follow manufacturer safety guidelines.',
    severity: 'warning',
    relatedTo: 'glue',
  },
  {
    id: '13',
    title: 'Use Adequate Clamping',
    description:
      'Properly clamp glued joints to ensure strong bonds. Use cauls to distribute pressure evenly across the joint.',
    severity: 'info',
    relatedTo: 'glue',
  },
  {
    id: '14',
    title: 'Allow Proper Drying Time',
    description:
      'Do not rush the drying process. Most wood glues need 24 hours to fully cure for maximum strength.',
    severity: 'warning',
    relatedTo: 'glue',
  },

  // Dovetail-related
  {
    id: '15',
    title: 'Sharp Chisels Are Safer',
    description:
      'A sharp chisel requires less force and is less likely to slip. Keep your chisels sharp for safer, cleaner cuts.',
    severity: 'warning',
    relatedTo: 'dovetail',
  },
  {
    id: '16',
    title: 'Cut Away From Body',
    description:
      'Always chisel away from your body and keep your hands behind the cutting edge. Use a vise to secure your work.',
    severity: 'danger',
    relatedTo: 'dovetail',
  },

  // Mortise-tenon-related
  {
    id: '17',
    title: 'Secure Workpiece Firmly',
    description:
      'When cutting mortises, ensure your workpiece is firmly clamped or secured in a vise. Movement can cause dangerous kickback.',
    severity: 'danger',
    relatedTo: 'mortise-tenon',
  },
  {
    id: '18',
    title: 'Use Proper Router Technique',
    description:
      'When using a router for mortises, always move against the rotation of the bit and use multiple shallow passes.',
    severity: 'warning',
    relatedTo: 'mortise-tenon',
  },

  // Dowel-related
  {
    id: '19',
    title: 'Use Dowel Jig for Accuracy',
    description:
      'A dowel jig ensures precise, aligned holes. Misaligned dowel holes can cause weak joints and assembly problems.',
    severity: 'info',
    relatedTo: 'dowel',
  },
  {
    id: '20',
    title: 'Clamp During Drilling',
    description:
      'Always clamp your workpiece when drilling dowel holes. A drill bit can catch and spin the workpiece, causing injury.',
    severity: 'danger',
    relatedTo: 'dowel',
  },

  // Pocket screw-related
  {
    id: '21',
    title: 'Use Proper Pocket Hole Jig',
    description:
      'A quality pocket hole jig ensures correct angles and prevents drill bit breakage. Never attempt pocket holes without a jig.',
    severity: 'warning',
    relatedTo: 'pocket-screw',
  },
  {
    id: '22',
    title: 'Select Correct Screw Length',
    description:
      'Using screws that are too long can break through the opposite face. Always calculate proper screw length for your material thickness.',
    severity: 'warning',
    relatedTo: 'pocket-screw',
  },

  // Brad nail-related
  {
    id: '23',
    title: 'Brad Nailer Air Pressure',
    description:
      'Adjust air pressure correctly for brad nailers. Too much pressure can blow through thin materials.',
    severity: 'warning',
    relatedTo: 'brad-nail',
  },
  {
    id: '24',
    title: 'Sequential vs. Contact Trigger',
    description:
      'Understand your nail gun trigger type. Contact triggers can accidentally discharge if bumped.',
    severity: 'danger',
    relatedTo: 'brad-nail',
  },

  // Additional general tips
  {
    id: '25',
    title: 'No Loose Clothing or Jewelry',
    description:
      'Remove jewelry and secure loose clothing before working with power tools. These can catch in moving parts.',
    severity: 'danger',
    relatedTo: 'general',
  },
  {
    id: '26',
    title: 'Use Push Sticks and Featherboards',
    description:
      'Keep your hands away from blades by using push sticks, push blocks, and featherboards when operating table saws and routers.',
    severity: 'danger',
    relatedTo: 'general',
  },
  {
    id: '27',
    title: 'Unplug Tools When Changing Blades',
    description:
      'Always disconnect power before changing blades, bits, or performing maintenance on power tools.',
    severity: 'danger',
    relatedTo: 'general',
  },
  {
    id: '28',
    title: 'First Aid Kit Available',
    description:
      'Keep a well-stocked first aid kit in your workshop and know how to use it. Know where the nearest phone is for emergencies.',
    severity: 'warning',
    relatedTo: 'general',
  },
  {
    id: '29',
    title: 'Proper Wood Finishing Ventilation',
    description:
      'Many finishes contain volatile organic compounds (VOCs). Always apply finishes in well-ventilated areas or outdoors.',
    severity: 'warning',
    relatedTo: 'general',
  },
  {
    id: '30',
    title: 'Store Flammable Materials Safely',
    description:
      'Store finishes, solvents, and oily rags in proper fire-safe containers. Spontaneous combustion from oily rags is a real hazard.',
    severity: 'danger',
    relatedTo: 'general',
  },
];

export const getSafetyTips = (req: Request, res: Response) => {
  const { relatedTo } = req.query;

  if (relatedTo) {
    const filtered = safetyTips.filter((tip) => tip.relatedTo === relatedTo);
    return res.json(filtered);
  }

  res.json(safetyTips);
};
