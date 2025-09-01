import type { Request, Response } from "express";
import Task from "../models/Task.js";
import type { ITask } from "../models/Task.js";
import type { AuthRequest } from "../middleware/authMiddleware.js";

// CREATE task for logged-in user
export const createTask = async (req: AuthRequest, res: Response) => {
  try {
    console.log("Creating task with data:", req.body);
    console.log("Step 1: About to log user ID");
    
    console.log("User ID:", req.user?.id);
    console.log("Step 2: User ID logged successfully");
    
    console.log("Step 3: About to destructure req.body");
    const { title, description, priority, deadline, completed } = req.body;
    console.log("Step 4: Destructured values:", { title, description, priority, deadline, completed });
    
    console.log("Step 5: About to create Task instance");
    const task = new Task({ title, description, priority, deadline, completed, user: req.user!.id });
    console.log("Step 6: Task instance created");
    
    console.log("Task to be saved:", task);
    console.log("Step 7: About to save task");
    
    await task.save();
    console.log("Step 8: Task saved successfully:", task);
    
    res.status(201).json(task);
  } catch (err) {
    console.error("Error creating task:", err);
    console.error("Error details:", JSON.stringify(err, null, 2));
    res.status(500).json({ error: "Failed to create task", details: err instanceof Error ? err.message : String(err) });
  }
};

// GET all tasks for the logged-in user
export const getTasks = async (req: AuthRequest, res: Response) => {
  try {
    const tasks = await Task.find({ user: req.user!.id });
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
};

// UPDATE task (only if it belongs to the logged-in user)
export const updateTask = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const task = await Task.findOneAndUpdate(
      { _id: id, user: req.user!.id }, // only allow own tasks
      req.body,
      { new: true }
    );
    if (!task) return res.status(404).json({ error: "Task not found" });
    res.json(task);
  } catch (err) {
    res.status(500).json({ error: "Failed to update task" });
  }
};

// DELETE task (only if it belongs to the logged-in user)
export const deleteTask = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const task = await Task.findOneAndDelete({ _id: id, user: req.user!.id });
    if (!task) return res.status(404).json({ error: "Task not found" });
    res.json({ message: "Task deleted" });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete task" });
  }
};
