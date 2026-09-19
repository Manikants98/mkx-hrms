fetch('https://api.mkx.monster/api/v1/attendance/generate-daily', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ date: '2026-09-20' })
}).then(r => r.json()).then(console.log).catch(console.error);
