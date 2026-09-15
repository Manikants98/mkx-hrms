import { Router } from "express";
import { handleContactSubmit } from "../controllers/contact.controller";
import { validate } from "../../middlewares/validate.middleware";
import { contactUsSchema } from "../schemas/contact.schema";

const router = Router();

router.post("/", validate(contactUsSchema), handleContactSubmit);

export default router;
