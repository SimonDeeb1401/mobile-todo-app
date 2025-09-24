import { Router } from "express";
import { createTask, getTasks, updateTask, deleteTask, moveTask, reorderAllTasks } from "../controllers/taskController.js";
import { verifyTokenLambda } from "../middleware/authMiddleware.js";

const router = Router();

// Add logging middleware
router.use((req, res, next) => {
  next();
});

router.post("/", verifyTokenLambda, createTask);
router.get("/", verifyTokenLambda, getTasks);
router.put("/:id", verifyTokenLambda, updateTask);
router.delete("/:id", verifyTokenLambda, deleteTask);
router.patch("/:id", verifyTokenLambda, updateTask);
router.patch("/:id/move", verifyTokenLambda, moveTask);
router.post("/reorder", verifyTokenLambda, reorderAllTasks);

export default router;
