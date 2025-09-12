import { Router } from "express";
import { getSortPreference, updateSortPreference } from "../controllers/userController.js";
import { verifyTokenLambda } from "../middleware/authMiddleware.js";

const router = Router();

router.patch("/", verifyTokenLambda, updateSortPreference);
router.get("/", verifyTokenLambda, getSortPreference);

export default router;
