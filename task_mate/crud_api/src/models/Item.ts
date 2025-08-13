import mongoose from "mongoose";

const itemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  quantity: { type: Number, default: 0 }
}, { timestamps: true });

export default mongoose.model("Item", itemSchema);
