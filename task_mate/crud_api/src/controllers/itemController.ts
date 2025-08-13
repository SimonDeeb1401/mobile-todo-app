import type { Request, Response } from "express";
import Item from "../models/Item.js";

export const createItem = async (req: Request, res: Response) => {
  try {
    const item = new Item(req.body);
    await item.save();
    res.status(201).json(item);
  } catch (err) {
    res.status(400).json({ message: err });
  }
};

export const getItems = async (_req: Request, res: Response) => {
  const items = await Item.find();
  res.json(items);
};

export const updateItem = async (req: Request, res: Response) => {
  try {
    const updated = await Item.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ message: err });
  }
};

export const deleteItem = async (req: Request, res: Response) => {
  try {
    await Item.findByIdAndDelete(req.params.id);
    res.sendStatus(204);
  } catch (err) {
    res.status(400).json({ message: err });
  }
};
