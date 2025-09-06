import jwt from "jsonwebtoken";
import { createResponse, extractToken, type LambdaEvent, type LambdaResponse } from "../index.js";

const JWT_SECRET = process.env.JWT_SECRET || "super_secret_key";

export interface AuthenticatedUser {
  id: string;
  email: string;
  sortPreference: { 
    mode: "createdAt" | "deadline" | "priority" | "manual"; 
    order: "asc" | "desc"; 
  };
}

export interface AuthRequest extends LambdaEvent {
  user?: AuthenticatedUser;
}

// Lambda-compatible auth middleware
export const verifyTokenLambda = (event: LambdaEvent): { user: AuthenticatedUser } | LambdaResponse => {
  const token = extractToken(event);
  
  if (!token) {
    return createResponse(401, { error: "No token provided" });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthenticatedUser;
    return { user: decoded };
  } catch (err) {
    return createResponse(401, { error: "Invalid token" });
  }
};

// Helper function to check if the result is an error response
export const isErrorResponse = (result: any): result is LambdaResponse => {
  return result && typeof result.statusCode === 'number' && typeof result.body === 'string';
};
