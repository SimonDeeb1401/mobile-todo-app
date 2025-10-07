import User from "../models/User.js";
import type { IUser } from "../models/User.js";
import { connectToDatabase, createResponse, parseBody, type LambdaEvent, type LambdaResponse } from "../index.js";
import { verifyTokenLambda, isErrorResponse, type AuthenticatedUser } from "../middleware/authMiddleware.js";
import mongoose, { get } from "mongoose";
import { getTasks } from "./taskController.js";
import Task from "../models/Task.js";

// Get user profile for logged-in user
export const getUserProfile = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();

    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }

    const user = authResult.user;

    // Find the user and get their profile information
    const userData: IUser | null = await User.findById(user.id).select('name age occupation email');
    if (!userData) {
      return createResponse(404, { error: "User not found" });
    }

    return createResponse(200, { 
      name: userData.name,
      age: userData.age,
      occupation: userData.occupation,
      email: userData.email
    });
  } catch (err) {
    console.error("Get user profile error:", err);
    return createResponse(500, { 
      error: "Failed to get user profile", 
      details: err instanceof Error ? err.message : String(err) 
    });
  }
};

// Get user preferences for logged-in user
export const getSortPreference = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    
    // Find the user and get their sort preferences
    const userData: IUser | null = await User.findById(user.id).select('sortPreference');
    
    if (!userData) {
      return createResponse(404, { error: "User not found" });
    }
    
    return createResponse(200, { 
      sortMode: userData.sortPreference.mode,
      sortOrder: userData.sortPreference.order,
      sortPreference: userData.sortPreference 
    });
    
  } catch (err) {
    console.error("Get user preferences error:", err);
    return createResponse(500, { 
      error: "Failed to get user preferences", 
      details: err instanceof Error ? err.message : String(err) 
    });
  }
};

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
    let tasks;

    if (updatedUser.sortPreference.mode === "manual") {
      tasks = await Task.find({ $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] }).sort({ completed: 1, orderIndex: 1 });
    }

    else if (updatedUser.sortPreference.mode === "priority") {
      tasks = await Task.aggregate([
        { $match: { $or: [
            { user: new mongoose.Types.ObjectId(user.id) }, 
            { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
        ] } },
        { $addFields: {
            priorityValue: { 
              $switch: {
                branches: [
                  { case: { $eq: ["$priority", "high"] }, then: 3 },
                  { case: { $eq: ["$priority", "medium"] }, then: 2 },
                  { case: { $eq: ["$priority", "low"] }, then: 1 }
                ],
                default: 4
              }
            }
          }
        },
        { $sort: { priorityValue: updatedUser.sortPreference.order === "asc" ? 1 : -1 }},
        { $project: { priorityValue: 0 }} 
      ]);
    }

    else {
      tasks =  await Task.find({ $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] }).sort({ [updatedUser.sortPreference.mode]: updatedUser.sortPreference.order === "asc" ? 1 : -1 });
    }

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