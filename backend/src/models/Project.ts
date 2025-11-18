import mongoose, { Schema, Document } from 'mongoose';
import type { Project as IProject } from '../../../shared/types/index.js';

interface ProjectDocument extends Omit<IProject, 'id' | 'createdAt' | 'updatedAt'>, Document {
  createdAt: Date;
  updatedAt: Date;
}

const woodPieceSchema = new Schema({
  id: { type: String, required: true },
  name: { type: String, required: true },
  woodType: { type: String, required: true },
  dimensions: {
    length: { type: Number, required: true },
    width: { type: Number, required: true },
    thickness: { type: Number, required: true },
  },
  position: {
    x: { type: Number, default: 0 },
    y: { type: Number, default: 0 },
    z: { type: Number, default: 0 },
  },
  rotation: {
    x: { type: Number, default: 0 },
    y: { type: Number, default: 0 },
    z: { type: Number, default: 0 },
  },
  color: String,
  texture: String,
});

const fasteningSchema = new Schema({
  id: { type: String, required: true },
  type: { type: String, required: true },
  position: {
    x: { type: Number, required: true },
    y: { type: Number, required: true },
    z: { type: Number, required: true },
  },
  connectedPieces: [{ type: String }],
  specifications: {
    size: String,
    length: Number,
    diameter: Number,
    quantity: Number,
  },
  strength: { type: String, enum: ['low', 'medium', 'high', 'very-high'], default: 'medium' },
});

const projectSchema = new Schema<ProjectDocument>(
  {
    name: { type: String, required: true },
    description: { type: String, default: '' },
    pieces: [woodPieceSchema],
    fastenings: [fasteningSchema],
    thumbnail: String,
    tags: [String],
  },
  {
    timestamps: true,
  }
);

export const ProjectModel = mongoose.model<ProjectDocument>('Project', projectSchema);
