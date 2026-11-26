import jwt from "jsonwebtoken";

const adminAuthMiddleware = async (req, res, next) => {
  const token = req.headers.token || req.headers.authorization?.split(" ")[1];
  if (!token) {
    return res.status(401).json({ success: false, message: "Not Authorized. Admin login required." });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.role !== "admin") {
      return res.status(403).json({ success: false, message: "Forbidden. Admin privileges required." });
    }
    req.admin = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: "Invalid or expired admin token." });
  }
};

export default adminAuthMiddleware;
