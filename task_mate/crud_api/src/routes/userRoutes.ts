import { Router } from "express";
import { updateSortPreference } from "../controllers/userController.js";
import { verifyTokenLambda } from "../middleware/authMiddleware.js";

const router = Router();

router.patch("/", verifyTokenLambda, updateSortPreference);

export default router;
