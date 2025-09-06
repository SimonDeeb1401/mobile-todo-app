import mongoose, { Schema, Document } from "mongoose";

export interface ITask extends Document {
  title: string;
  description?: string;
  priority: "low" | "medium" | "high";
  deadline: Date;
  completed: boolean;
  user: mongoose.Types.ObjectId;
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
  orderIndex: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

export default mongoose.model<ITask>("Task", taskSchema);
