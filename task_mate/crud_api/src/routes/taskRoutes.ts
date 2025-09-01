import { Router } from "express";
import { createTask, getTasks, updateTask, deleteTask } from "../controllers/taskController.js";
import { verifyToken } from "../middleware/authMiddleware.js";

const router = Router();

// Add logging middleware
router.use((req, res, next) => {
  console.log(`Task route accessed: ${req.method} ${req.path}`);
  console.log("Request body:", req.body);
  next();
});

router.post("/", verifyToken, createTask);
router.get("/", verifyToken, getTasks);
router.put("/:id", verifyToken, updateTask);
router.delete("/:id", verifyToken, deleteTask);
router.patch("/:id", verifyToken, updateTask);

export default router;
