import User from "../models/User.js";
import type { IUser } from "../models/User.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { connectToDatabase, createResponse, parseBody, type LambdaEvent, type LambdaResponse } from "../index.js";

const JWT_SECRET = process.env.JWT_SECRET;

export const signup = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();

    const { email, password, name, age, occupation } = parseBody(event);

    if (!email || !password || !name || !age || !occupation) {
      return createResponse(400, { error: "All fields are required" });
    }
    
    const hashed = await bcrypt.hash(password, 10);
    const user = new User({ email, password: hashed, name, age, occupation });
    await user.save();
    
    return createResponse(201, { message: "User created" });
  } catch (err: any) {
    if (err.code === 11000) {
      return createResponse(400, { error: "User already exists" });
    }
    console.error("Signup error:", err);
    return createResponse(500, { error: "Server error" });
  }
};

export const login = async (event: LambdaEvent): Promise<LambdaResponse> => {
  try {
    await connectToDatabase();
    
    const { email, password } = parseBody(event);
    
    if (!email || !password) {
      return createResponse(400, { error: "Email and password are required" });
    }
    
    const user: IUser | null = await User.findOne({ email });
    
    if (!user) {
      return createResponse(400, { error: "Invalid credentials" });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return createResponse(400, { error: "Invalid credentials" });
    }

    if (!JWT_SECRET || typeof JWT_SECRET !== "string") {
      console.error("JWT_SECRET is not defined or not a string");
      return createResponse(500, { error: "Server configuration error" });
    }
    const token = jwt.sign({ id: user._id, email: user.email, sortPreference: user.sortPreference }, JWT_SECRET, { expiresIn: "1h" });

    return createResponse(200, { token });
  } catch (err) {
    console.error("Login error:", err);
    return createResponse(500, { error: "Server error" });
  }
};