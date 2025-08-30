import mongoose, { Schema, Document } from "mongoose";

export interface IItem extends Document {
  title: string;
  description?: string;
  priority: "low" | "medium" | "high";
  deadline: Date;
  completed: boolean;
  user: mongoose.Types.ObjectId;
}

const itemSchema: Schema = new Schema({
  title: { type: String, required: true },
  description: { type: String },
  priority: { type: String, enum: ["low", "medium", "high"], default: "medium" },
  deadline: { type: Date, required: true },
  completed: { type: Boolean, default: false },
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }
});

export default mongoose.model<IItem>("Item", itemSchema);
