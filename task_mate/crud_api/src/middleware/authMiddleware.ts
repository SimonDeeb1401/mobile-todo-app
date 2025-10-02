import jwt from "jsonwebtoken";
import { createResponse, extractToken, type LambdaEvent, type LambdaResponse } from "../index.js";

const JWT_SECRET = process.env.JWT_SECRET;

export interface AuthenticatedUser {
  name: string;
  age: number;
  occupation: string;
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
    if (!JWT_SECRET || typeof JWT_SECRET !== "string") {
      console.error("JWT_SECRET is not defined or not a string");
      return createResponse(500, { error: "Server configuration error" });
    }
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
