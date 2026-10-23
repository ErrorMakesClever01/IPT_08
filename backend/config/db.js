import mongoose from "mongoose";

export const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error("MONGO_URI is not set");
    process.exit(1);
  }
  for (let attempt = 1; attempt <= 10; attempt++) {
    try {
      await mongoose.connect(uri);
      console.log("DB Connected");
      return;
    } catch (err) {
      console.error(`DB connect failed (attempt ${attempt}/10): ${err.message}`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
  process.exit(1);
};