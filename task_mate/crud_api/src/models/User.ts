import mongoose, { Schema, Document } from "mongoose";

export interface IUser extends Document {
  name: string;
  age: number;
  occupation: string;
  email: string;
  password: string;
  sortPreference: { 
    mode: "createdAt" | "deadline" | "priority" | "manual"; 
    order: "asc" | "desc";
  }
}

const userSchema: Schema = new Schema({
  name: { type: String, required: true },
  age: { type: Number, required: true },
  occupation: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  sortPreference: {
    mode: { type: String, enum: ["createdAt", "deadline", "priority", "manual"], default: "createdAt" },
    order: { type: String, enum: ["asc", "desc"], default: "asc" }
  },
});

export default mongoose.model<IUser>("User", userSchema);
