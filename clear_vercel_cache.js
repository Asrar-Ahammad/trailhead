const jwt = require('jsonwebtoken');

const JWT_SECRET = "99401fcdae48ad836f34336c8565eab46aaf7dadb323d712b5e810bf616574fa";
const userId = "cmrcaziyy0000lb04foawv8ef";

const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });

async function clearCache() {
  console.log('Sending POST to create dummy manual PR...');
  const postRes = await fetch('https://trailhead-seven.vercel.app/api/records/manual', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      category: 'test_clear_cache',
      value: 1,
      achievedAt: new Date().toISOString()
    })
  });
  const postData = await postRes.json();
  console.log('POST result:', postData);

  if (postData.id) {
    console.log('Deleting dummy manual PR...');
    const delRes = await fetch(`https://trailhead-seven.vercel.app/api/records/manual/${postData.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('DELETE status:', delRes.status);
  }
}

clearCache();
