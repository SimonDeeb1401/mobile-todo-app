import mongoose, { Schema, Document } from "mongoose";

export interface IItem extends Document {
  title: string;
  description?: string;
  user: mongoose.Types.ObjectId;
}

const itemSchema: Schema = new Schema({
  title: { type: String, required: true },
  description: { type: String },
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }
});

export default mongoose.model<IItem>("Item", itemSchema);
