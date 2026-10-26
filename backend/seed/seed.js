// Fills the "food" collection with starter data.
// Safe to run many times: it does nothing if food items already exist.
import 'dotenv/config'
import fs from 'fs'
import mongoose from 'mongoose'
import foodModel from '../models/foodModel.js'

const uri = process.env.MONGO_URI
if (!uri) {
  console.error('MONGO_URI is not set')
  process.exit(1)
}

const foods = JSON.parse(
  fs.readFileSync(new URL('./foods.json', import.meta.url), 'utf8')
)

try {
  await mongoose.connect(uri)
  const existing = await foodModel.countDocuments()
  if (existing > 0) {
    console.log(`Seed skipped: ${existing} food items already in the database`)
  } else {
    await foodModel.insertMany(foods)
    console.log(`Seed done: inserted ${foods.length} food items`)
  }
  await mongoose.disconnect()
} catch (err) {
  console.error('Seed failed:', err.message)
  process.exit(1)
}
