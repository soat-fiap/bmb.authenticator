import jwt from "jsonwebtoken";

export function generateAccessToken(payload) {
  return jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: process.env.ACCESS_TOKEN_EXP,
    issuer: process.env.ACCESS_TOKEN_ISSUER,
    audience: process.env.ACCESS_TOKEN_AUDIENCE,
  });
}