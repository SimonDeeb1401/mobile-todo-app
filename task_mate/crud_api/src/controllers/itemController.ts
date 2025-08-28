import type { Request, Response } from "express";
import Item from "../models/Item.js";
import type { IItem } from "../models/Item.js";
import type { AuthRequest } from "../middleware/authMiddleware.js";

// CREATE item for logged-in user
export const createItem = async (req: AuthRequest, res: Response) => {
  try {
    const { title, description } = req.body;
    const item = new Item({ title, description, user: req.user!.id });
    await item.save();
    res.status(201).json(item);
  } catch (err) {
    res.status(500).json({ error: "Failed to create item" });
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
