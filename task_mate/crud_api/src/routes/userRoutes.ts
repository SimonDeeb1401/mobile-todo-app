import { Router } from "express";
import { getSortPreference, updateSortPreference, getUserProfile } from "../controllers/userController.js";
import { verifyTokenLambda } from "../middleware/authMiddleware.js";

const router = Router();

router.patch("/", verifyTokenLambda, updateSortPreference);
router.get("/", verifyTokenLambda, getSortPreference);
router.get("/profile", verifyTokenLambda, getUserProfile);

export default router;
