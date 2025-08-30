import type { Request, Response } from "express";
import Item from "../models/Item.js";
import type { IItem } from "../models/Item.js";
import type { AuthRequest } from "../middleware/authMiddleware.js";

// CREATE item for logged-in user
export const createItem = async (req: AuthRequest, res: Response) => {
  try {
    console.log("Creating item with data:", req.body);
    console.log("Step 1: About to log user ID");
    
    console.log("User ID:", req.user?.id);
    console.log("Step 2: User ID logged successfully");
    
    console.log("Step 3: About to destructure req.body");
    const { title, description, priority, deadline, completed } = req.body;
    console.log("Step 4: Destructured values:", { title, description, priority, deadline, completed });
    
    console.log("Step 5: About to create Item instance");
    const item = new Item({ title, description, priority, deadline, completed, user: req.user!.id });
    console.log("Step 6: Item instance created");
    
    console.log("Item to be saved:", item);
    console.log("Step 7: About to save item");
    
    await item.save();
    console.log("Step 8: Item saved successfully:", item);
    
    res.status(201).json(item);
  } catch (err) {
    console.error("Error creating item:", err);
    console.error("Error details:", JSON.stringify(err, null, 2));
    res.status(500).json({ error: "Failed to create item", details: err instanceof Error ? err.message : String(err) });
  }
};

// GET all items for the logged-in user
export const getItems = async (req: AuthRequest, res: Response) => {
  try {
    const items = await Item.find({ user: req.user!.id });
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch items" });
  }
};

// UPDATE item (only if it belongs to the logged-in user)
export const updateItem = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const item = await Item.findOneAndUpdate(
      { _id: id, user: req.user!.id }, // only allow own items
      req.body,
      { new: true }
    );
    if (!item) return res.status(404).json({ error: "Item not found" });
    res.json(item);
  } catch (err) {
    res.status(500).json({ error: "Failed to update item" });
  }
};

// DELETE item (only if it belongs to the logged-in user)
export const deleteItem = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const item = await Item.findOneAndDelete({ _id: id, user: req.user!.id });
    if (!item) return res.status(404).json({ error: "Item not found" });
    res.json({ message: "Item deleted" });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete item" });
  }
};
