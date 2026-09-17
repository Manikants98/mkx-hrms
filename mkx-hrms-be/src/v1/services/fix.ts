import { prisma } from "../../libraries/prisma";

async function main() {
  await prisma.jobPosting.update({
    where: { id: 1 },
    data: {
      role_id: 3,
      shift_id: 1
    }
  });
  console.log("Updated Job Posting 1 with Role 3 and Shift 1");
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
