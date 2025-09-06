import mongoose, { Schema, Document } from "mongoose";

export interface IUser extends Document {
  email: string;
  password: string;
  sortPreference: { 
    mode: "createdAt" | "deadline" | "priority" | "manual"; 
    order: "asc" | "desc";
  }
}

const userSchema: Schema = new Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  sortPreference: {
    mode: { type: String, enum: ["createdAt", "deadline", "priority", "manual"], default: "createdAt" },
    order: { type: String, enum: ["asc", "desc"], default: "asc" }
  },
});

export default mongoose.model<IUser>("User", userSchema);
