import 'dotenv/config'
import express from "express"
import cors from 'cors'
import mongoose from "mongoose"
import { connectDB } from "./config/db.js"
import userRouter from "./routes/userRoute.js"
import foodRouter from "./routes/foodRoute.js"
import cartRouter from "./routes/cartRoute.js"
import orderRouter from "./routes/orderRoute.js"

const app = express()
const port = process.env.PORT || 4000;
app.use(express.json())

const allowedOrigins = [
  "http://tomato-foods.duckdns.org",
  "http://admin.tomato-foods.duckdns.org",
  "http://localhost:5173",
  "http://localhost:5174"
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (curl, ELB health checks, mobile apps) or whitelisted origins
    if (!origin || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error("CORS policy: Origin not allowed"), false);
  },
  credentials: true
}));

app.use("/api/user", userRouter)
app.use("/api/food", foodRouter)
app.use("/images", express.static('uploads'))
app.use("/api/cart", cartRouter)
app.use("/api/order", orderRouter)

app.get("/", (req, res) => res.send("API Working"));

await connectDB();
app.listen(port, () => console.log(`Server started on port ${port}`));
