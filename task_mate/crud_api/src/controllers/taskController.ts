import Task from "../models/Task.js";
import type { ITask } from "../models/Task.js";
import { connectToDatabase, createResponse, parseBody, type LambdaEvent, type LambdaResponse } from "../index.js";
import { verifyTokenLambda, isErrorResponse, type AuthenticatedUser } from "../middleware/authMiddleware.js";

// CREATE task for logged-in user
export const createTask = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const { title, description, priority, deadline, completed } = parseBody(event);
    
    if (!title) {
      return createResponse(400, { error: "Title is required" });
    }
    
    const task = new Task({ 
      title, 
      description, 
      priority, 
      deadline: deadline ? new Date(deadline) : undefined, 
      completed: completed || false, 
      user: user.id 
    });
    
    await task.save();
    return createResponse(201, task);
  } catch (err) {
    console.error("Create task error:", err);
    return createResponse(500, { 
      error: "Failed to create task", 
      details: err instanceof Error ? err.message : String(err) 
    });
  }
};

// GET all tasks for the logged-in user
export const getTasks = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const tasks = await Task.find({ user: user.id });
    
    return createResponse(200, tasks);
  } catch (err) {
    console.error("Get tasks error:", err);
    return createResponse(500, { error: "Failed to fetch tasks" });
  }
};

// UPDATE task (only if it belongs to the logged-in user)
export const updateTask = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const id = event.pathParameters?.id;
    
    if (!id) {
      return createResponse(400, { error: "Task ID is required" });
    }
    
    const updateData = parseBody(event);
    
    // Convert deadline to Date if provided
    if (updateData.deadline) {
      updateData.deadline = new Date(updateData.deadline);
    }
    
    const task = await Task.findOneAndUpdate(
      { _id: id, user: user.id }, // only allow own tasks
      updateData,
      { new: true }
    );
    
    if (!task) {
      return createResponse(404, { error: "Task not found" });
    }
    
    return createResponse(200, task);
  } catch (err) {
    console.error("Update task error:", err);
    return createResponse(500, { error: "Failed to update task" });
  }
};

// DELETE task (only if it belongs to the logged-in user)
export const deleteTask = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const id = event.pathParameters?.id;
    
    if (!id) {
      return createResponse(400, { error: "Task ID is required" });
    }
    
    const task = await Task.findOneAndDelete({ _id: id, user: user.id });
    
    if (!task) {
      return createResponse(404, { error: "Task not found" });
    }
    
    return createResponse(200, { message: "Task deleted" });
  } catch (err) {
    console.error("Delete task error:", err);
    return createResponse(500, { error: "Failed to delete task" });
  }
};
