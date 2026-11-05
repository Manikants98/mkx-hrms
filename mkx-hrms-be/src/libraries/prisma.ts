import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";

/**
 * PostgreSQL connection string from environment
 */
const connectionString = process.env.DATABASE_URL;

/**
 * PostgreSQL connection pool
 */
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);

/**
 * Global Prisma Client instance
 */
export const prisma = new PrismaClient({ adapter });
