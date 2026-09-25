const { Client } = require("pg");
const c = new Client({
  connectionString:
    "postgresql://mkx_admin:EciLvJV1G72H6lmRw3jxjrtuU36BYih8@dpg-dafvio0u01pc73c7hjeg-a.singapore-postgres.render.com/mkx_hrms?sslmode=require",
});
c.connect()
  .then(() =>
    c.query(
      `SELECT e.id as emp_id, e.name as emp_name, e.user_id as emp_user_id, u.id as user_id, u.email, u.fcm_token FROM employees e LEFT JOIN users u ON e.user_id = u.id`,
    ),
  )
  .then((r) => {
    console.log(r.rows);
    c.end();
  })
  .catch((e) => {
    console.error(e);
    c.end();
  });
