import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

// MongoDB connection state
let isConnected = false;

// Connect to MongoDB (reuse connection across Lambda invocations)
export const connectToDatabase = async () => {
  if (isConnected) {
    return;
  }

  const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI || "";
  
  if (!MONGO_URI) {
    throw new Error("MongoDB URI is not defined in environment variables");
  }

  try {
    await mongoose.connect(MONGO_URI);
    isConnected = true;
    console.log("✅ Connected to MongoDB");
  } catch (err) {
    console.error("❌ MongoDB connection error:", err);
    throw err;
  }
};

// Lambda handler type
export interface LambdaEvent {
  httpMethod: string;
  path: string;
  pathParameters?: { [key: string]: string };
  queryStringParameters?: { [key: string]: string };
  headers: { [key: string]: string };
  body?: string;
  requestContext?: any;
}

export interface LambdaResponse {
  statusCode: number;
  headers?: { [key: string]: string };
  body: string;
}

// CORS headers for all responses
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Content-Type": "application/json"
};

// Helper function to create Lambda response
export const createResponse = (statusCode: number, body: any): LambdaResponse => ({
  statusCode,
  headers: corsHeaders,
  body: JSON.stringify(body)
});

// Helper function to parse request body
export const parseBody = (event: LambdaEvent) => {
  if (!event.body) return {};
  try {
    return JSON.parse(event.body);
  } catch {
    return {};
  }
};

// Helper function to extract auth token from headers
export const extractToken = (event: LambdaEvent): string | null => {
  const authHeader = event.headers.Authorization || event.headers.authorization;
  if (!authHeader) return null;
  
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") return null;
  
  return parts[1] || null;
};