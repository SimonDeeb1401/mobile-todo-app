import { Router } from "express";
import { createItem, getItems, updateItem, deleteItem } from "../controllers/itemController.js";
import { verifyToken } from "../middleware/authMiddleware.js";

const router = Router();

router.post("/", verifyToken, createItem);
router.get("/", verifyToken, getItems);
router.put("/:id", verifyToken, updateItem);
router.delete("/:id", verifyToken, deleteItem);

export default router;
