// src/server.ts
import express from "express";
import cors from "cors";
import * as auth from "./controllers/authController.js";
import * as tasks from "./controllers/taskController.js";
import * as user from "./controllers/userController.js";
import type { LambdaEvent } from "./index.js";

const app = express();
app.use(cors());
app.use(express.json());

// Adapter: turns an Express req into your existing LambdaEvent shape
const wrap = (handler: (e: LambdaEvent) => Promise<any>) => async (req: any, res: any) => {
  const event: LambdaEvent = {
    httpMethod: req.method,
    path: req.path,
    pathParameters: req.params,
    queryStringParameters: req.query,
    headers: req.headers,
    body: JSON.stringify(req.body ?? {}),
  };
  const result = await handler(event);
  res.status(result.statusCode).set(result.headers).send(result.body);
};

app.post("/api/auth/signup", wrap(auth.signup));
app.post("/api/auth/login", wrap(auth.login));
app.post("/api/tasks", wrap(tasks.createTask));
app.get("/api/tasks", wrap(tasks.getTasks));
app.put("/api/tasks/:id", wrap(tasks.updateTask));
app.patch("/api/tasks/:id", wrap(tasks.updateTask));
app.delete("/api/tasks/:id", wrap(tasks.deleteTask));
app.patch("/api/tasks/:id/move", wrap(tasks.moveTask));
app.post("/api/tasks/reorder", wrap(tasks.reorderAllTasks));
app.get("/api/user/sortPreference", wrap(user.getSortPreference));
app.patch("/api/user/sortPreference", wrap(user.updateSortPreference));

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`API listening on ${PORT}`));