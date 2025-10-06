import mongoose, { Schema, Document } from "mongoose";
import { title } from "process";

export interface ITask extends Document {
  title: string;
  description?: string;
  priority: "low" | "medium" | "high";
  deadline: Date;
  completed: boolean;
  user: mongoose.Types.ObjectId;
  collaborators?: mongoose.Types.ObjectId[];
  comments?: { user: mongoose.Types.ObjectId; text: string; createdAt: Date }[];
  orderIndex: number;
  createdAt: Date;
  updatedAt: Date;
}

const taskSchema: Schema = new Schema({
  title: { type: String, required: true },
  description: { type: String },
  priority: { type: String, enum: ["low", "medium", "high"], default: "medium" },
  deadline: { type: Date, required: true },
  completed: { type: Boolean, default: false },
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  collaborators: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
  comments: [
    {
      user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
      text: { type: String, required: true },
      createdAt: { type: Date, default: Date.now }
    }
  ],
  orderIndex: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

taskSchema.index({ title: "text", description: "text" });

taskSchema.index({ user: 1, orderIndex: 1 });

export default mongoose.model<ITask>("Task", taskSchema);
