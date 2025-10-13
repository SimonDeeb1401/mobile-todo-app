import Task from "../models/Task.js";
import type { ITask } from "../models/Task.js";
import { connectToDatabase, createResponse, parseBody, type LambdaEvent, type LambdaResponse } from "../index.js";
import { verifyTokenLambda, isErrorResponse, type AuthenticatedUser } from "../middleware/authMiddleware.js";
import mongoose from "mongoose";
import User from "../models/User.js";
import { normalize } from "path";

const STEP = 1000; // Step value for orderIndex gaps

type ResolveResult = {
  collaboratorIds: mongoose.Types.ObjectId[];
  notFound: string[]; // normalized emails that weren't matched
};

// CREATE task for logged-in user
export const createTask = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }
    
    const user = authResult.user;
    const { title, description, priority, deadline, completed, collaborators } = parseBody(event);
    
    if (!title) {
      return createResponse(400, { error: "Title is required" });
    }

    const { collaboratorIds, notFound } = await resolveCollaboratorIdsByEmail(collaborators);

    if (notFound.length > 0) {
      return createResponse(400, {
        error: "Some collaborators were not found",
        details: { unknownEmails: notFound },
      });
    }

    const maxOrderTask = await Task.findOne({ user: user.id, completed: false })
      .sort({ orderIndex: -1 })
      .select('orderIndex');

    const newOrderIndex = maxOrderTask ? maxOrderTask.orderIndex + STEP : STEP;
    
    const task = new Task({ 
      title, 
      description, 
      priority, 
      deadline: deadline ? new Date(deadline) : undefined, 
      completed: completed || false, 
      user: user.id,
      collaborators: collaboratorIds,
      orderIndex: newOrderIndex
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

    const { search } = event.queryStringParameters || {};
    const filter: any = { $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] };

    if (search) {
      filter.$text = { $search: search };
    }

    let tasks;

    if (user.sortPreference.mode === "manual") {
      //tasks = await Task.find({ $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] }).sort({ completed: 1, orderIndex: 1 });
      tasks = await Task.aggregate([
        { $match: { $or: [
            { user: new mongoose.Types.ObjectId(user.id) },
            { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
        ] } },
        { $addFields: {
            hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
        }},
        { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
        { $project: { hasNoCollaborators: 0 } }
      ]);
    }

    else if (user.sortPreference.mode === "priority") {
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
        { $sort: { priorityValue: user.sortPreference.order === "asc" ? 1 : -1 }},
        { $project: { priorityValue: 0 }} 
      ]);
    }

    else{
      tasks = await Task.find({ $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] }).sort({ [user.sortPreference.mode]: user.sortPreference.order === "asc" ? 1 : -1 });
    }
    
    
    console.log("Fetched tasks:", tasks);

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

    if(Array.isArray(updateData.collaborators)){
      const { collaboratorIds, notFound } = await resolveCollaboratorIdsByEmail(updateData.collaborators);
      if (notFound.length > 0) {
        return createResponse(400, {
          error: "Some collaborators were not found",
          details: { unknownEmails: notFound },
        });
      }
      updateData.collaborators = collaboratorIds;
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

export const moveTask = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();

    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }

    const user = authResult.user;
    const orderedTaskId = event.pathParameters?.id;
    const { newIndex } = parseBody(event);

    const totalTasksCount = await Task.countDocuments({ $or: [{ user: user.id }, { collaborators: { $elemMatch: { $eq: user.id } } }] });

    if (newIndex < 0 || newIndex >= totalTasksCount) {
      return createResponse(400, { error: "Invalid new index" });
    }

    //const allTasksSorted = await Task.find({ user: user.id }).sort({ completed: 1, orderIndex: 1 }).select('_id orderIndex completed');
    const allTasksSorted = await Task.aggregate([
      { $match: { $or: [
          { user: new mongoose.Types.ObjectId(user.id) },
          { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
      ] } },
      { $addFields: {
          hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
      }},
      { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
      { $project: { hasNoCollaborators: 0 } }
    ]);
    const ids = allTasksSorted.map(t => String(t._id));
    const currentIndex = ids.indexOf(String(orderedTaskId));
    if (currentIndex === -1) {
      return createResponse(404, { error: "Task not found" });
    }

    ids.splice(currentIndex, 1); // remove from current position
    ids.splice(newIndex, 0, String(orderedTaskId)); // insert at new position

    const position = ids.indexOf(String(orderedTaskId));
    const prevId = position > 0 ? ids[position - 1] : null;
    const nextId = position < ids.length - 1 ? ids[position + 1] : null;

    let newOrderIndex: number;
    if(!prevId && !nextId) {
      newOrderIndex = STEP; // First and only task
    }
    else if (!prevId) {
      const nextOrderIndex = allTasksSorted.find(t => String(t._id) === nextId)!.orderIndex;
      newOrderIndex = Math.floor(nextOrderIndex / 2);
      if(newOrderIndex <= 0){
        await normalizeOrderIndexes(user.id);
        //const updated = await Task.find({ user: user.id }).sort({ completed: 1, orderIndex: 1 }).select('_id orderIndex completed');
        const updated = await Task.aggregate([
          { $match: { $or: [
              { user: new mongoose.Types.ObjectId(user.id) },
              { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
          ] } },
          { $addFields: {
              hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
          }},
          { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
          { $project: { hasNoCollaborators: 0 } }
        ]);
        const nextUpdated = updated.find(t => String(t._id) === nextId)!;
        newOrderIndex = Math.floor(nextUpdated.orderIndex / 2);
      }
    }
    else if (!nextId) {
      const prevOrderIndex = allTasksSorted.find(t => String(t._id) === prevId)!.orderIndex;
      newOrderIndex = prevOrderIndex + STEP;
    }
    else {
      const prevOrderIndex = allTasksSorted.find(t => String(t._id) === prevId)!.orderIndex;
      const nextOrderIndex = allTasksSorted.find(t => String(t._id) === nextId)!.orderIndex;
      if(nextOrderIndex - prevOrderIndex > 1){
        newOrderIndex = Math.floor((prevOrderIndex + nextOrderIndex) / 2);
      }
      else{
        await normalizeOrderIndexes(user.id);
        //const updated = await Task.find({ user: user.id }).sort({ completed: 1, orderIndex: 1 }).select('_id orderIndex completed');
        const updated = await Task.aggregate([
          { $match: { $or: [
              { user: new mongoose.Types.ObjectId(user.id) },
              { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
          ] } },
          { $addFields: {
              hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
          }},
          { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
          { $project: { hasNoCollaborators: 0 } }
        ]);
        const prevUpdated = updated.find(t => String(t._id) === prevId)!;
        const nextUpdated = updated.find(t => String(t._id) === nextId)!;
        newOrderIndex = Math.floor((prevUpdated.orderIndex + nextUpdated.orderIndex) / 2);
      }
    }

    await Task.updateOne({_id: orderedTaskId, user: user.id},{ $set: { orderIndex: newOrderIndex }});

    const movedTask = await Task.findById(orderedTaskId);
    //const allTasksAfterMove = await Task.find({ user: user.id }).sort({ completed: 1, orderIndex: 1 });
    const allTasksAfterMove = await Task.aggregate([
        { $match: { $or: [
              { user: new mongoose.Types.ObjectId(user.id) },
              { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(user.id) } } }
          ] } },
        { $addFields: {
            hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
        }},
        { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
        { $project: { hasNoCollaborators: 0 } }
      ]);
    return createResponse(200, { success: true, task: movedTask, tasks: allTasksAfterMove });
  } 

  catch (err) {
    console.error("Move task error:", err);
    return createResponse(500, { error: "Failed to move task" });
  }
};

export const reorderAllTasks = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();

    const authResult = verifyTokenLambda(event);
    if (isErrorResponse(authResult)) {
      return authResult;
    }

    const user = authResult.user;
    const { orderedTaskIds } = parseBody(event);
    const bulk = orderedTaskIds.map((id: string, index: number) => ({
      updateOne: {
        filter: { _id: id, user: user.id },
        update: { $set: { orderIndex: (index + 1) * STEP } }
      }
    }));
    await Task.bulkWrite(bulk);
    return createResponse(200, { success: true });
  }
  
  catch (err) {
    console.error("Reorder all tasks error:", err);
    return createResponse(500, { error: "Failed to reorder tasks" });
  }
};

async function normalizeOrderIndexes(userId: string) {
  //const allTasks = await Task.find({ user: userId }).sort({ completed: 1, orderIndex: 1 }).select('_id');
  const allTasks = await Task.aggregate([
    { $match: { $or: [
              { user: new mongoose.Types.ObjectId(userId) },
              { collaborators: { $elemMatch: { $eq: new mongoose.Types.ObjectId(userId) } } }
          ] } },
    { $addFields: {
        hasNoCollaborators: { $eq: [ { $size: "$collaborators" }, 0 ] }
    }},
    { $sort: { hasNoCollaborators: -1, completed: 1, orderIndex: 1 } },
    { $project: { hasNoCollaborators: 0 } }
  ]);
  const bulkOps = allTasks.map((task, index) => ({
    updateOne: {
      filter: { _id: task._id },
      update: { $set: { orderIndex: (index + 1) * STEP } }
    }
  }));
  if(bulkOps.length){
    await Task.bulkWrite(bulkOps);
  }
}

async function resolveCollaboratorIdsByEmail(emails: unknown): Promise<ResolveResult> {
  if (!Array.isArray(emails)) {
    return { collaboratorIds: [], notFound: [] };
  }

  // 1) Normalize and dedupe
  const original = emails
    .map((e) => (typeof e === "string" ? e : ""))
    .filter((e) => e.length > 0);

  const unique = Array.from(new Set(original));
  if (unique.length === 0) {
    return { collaboratorIds: [], notFound: [] };
  }

  // 2) Single indexed query on email (unique index => efficient)
  const users = await User.find({ email: { $in: unique } })
    .select("_id email")
    .lean();

  // 3) Build a lookup map email -> _id
  const emailToId = new Map<string, mongoose.Types.ObjectId>();
  users.forEach((u) => {
    const key = (u as any).email;
    emailToId.set(key, (u as any)._id as mongoose.Types.ObjectId);
  });

  // 4) Preserve original order, filter duplicates, compute notFound
  const seen = new Set<string>();
  const collaboratorIds: mongoose.Types.ObjectId[] = [];
  const notFound: string[] = [];

  original.forEach((e) => {
    if (seen.has(e)) return;
    seen.add(e);
    const id = emailToId.get(e);
    if (id) {
      collaboratorIds.push(id);
    } else {
      notFound.push(e);
    }
  });

  return { collaboratorIds, notFound };
}