import User from "../models/User.js";
import type { IUser } from "../models/User.js";
import { connectToDatabase, createResponse, parseBody, type LambdaEvent, type LambdaResponse } from "../index.js";
import { verifyTokenLambda, isErrorResponse, type AuthenticatedUser } from "../middleware/authMiddleware.js";
import { get } from "mongoose";
import { getTasks } from "./taskController.js";
import Task from "../models/Task.js";

// update sort preference for logged-in user
export const updateSortPreference = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const { mode, order } = parseBody(event);
    
    if (!mode || !order || !["createdAt", "deadline", "priority", "manual"].includes(mode) || !["asc", "desc"].includes(order)) {
      return createResponse(400, { error: "Invalid sort preference" });
    }
    
    const updatedUser: IUser | null = await User.findByIdAndUpdate(user.id, { sortPreference: { mode, order } }, { new: true });
    
    if (!updatedUser) {
      return createResponse(404, { error: "User not found" });
    }
    
    //const tasksResponse = await getTasks(event);
    const tasks = (updatedUser.sortPreference.mode != "manual") 
          ? await Task.find({ user: user.id }).sort({ [updatedUser.sortPreference.mode]: updatedUser.sortPreference.order === "asc" ? 1 : -1 }) 
          : await Task.find({ user: user.id });
    console.log("Tasks after sort preference update:", tasks);

    return createResponse(200, { message: "Sort preference updated", sortPreference: updatedUser.sortPreference, tasks: tasks });
  } catch (err) {
    console.error("Update sort preference error:", err);
    return createResponse(500, { 
      error: "Failed to update sort preference", 
      details: err instanceof Error ? err.message : String(err) 
    });
  }
}