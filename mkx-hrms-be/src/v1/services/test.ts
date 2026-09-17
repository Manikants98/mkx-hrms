import { prisma } from "../../libraries/prisma";

async function main() {
  const roles = await prisma.role.findMany();
  const shifts = await prisma.workShift.findMany();
  const candidates = await prisma.candidate.findMany({ include: { job_posting: true }});
  const employees = await prisma.employee.findMany();
  
  console.log("ROLES:", roles.map(r => ({ id: r.id, name: r.name })));
  console.log("SHIFTS:", shifts.map(s => ({ id: s.id, name: s.name, start: s.start_time, end: s.end_time })));
  console.log("CANDIDATES:", candidates.map(c => ({ id: c.id, name: c.name, position: c.position, job_posting_id: c.job_posting_id, jp_role: c.job_posting?.role_id, jp_shift: c.job_posting?.shift_id })));
  console.log("EMPLOYEES:", employees.map(e => ({ id: e.id, name: e.name, role_id: e.role_id, shift_id: e.shift_id })));
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
