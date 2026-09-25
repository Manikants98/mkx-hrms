import { prisma } from "./src/libraries/prisma";

async function main() {
  const user = await prisma.user.findUnique({
    where: { email: "dadzheromani@gmail.com" },
  });
  console.log("--- USER INFO ---");
  console.log("User:", user?.first_name, user?.last_name);
  console.log("Email:", user?.email);
  console.log("FCM Token:", user?.fcm_token ? "EXISTS: " + user.fcm_token : "NULL or EMPTY");
  console.log("-----------------");
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
