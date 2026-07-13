import { dbServer } from '@/lib/db-server';

export default async function ShoesDashboard() {
  const shoes = await dbServer.shoe.findMany({
    include: {
      user: true,
      runs: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  return (
    <div style={{ padding: '2rem', fontFamily: 'monospace', backgroundColor: '#121212', color: '#fff', minHeight: '100vh' }}>
      <h1 style={{ color: '#4ade80', fontSize: '2rem', marginBottom: '1rem' }}>Trailhead - Shoes Dashboard</h1>
      <p style={{ color: '#888', marginBottom: '2rem' }}>A quick overview of all shoes stored in the backend.</p>

      {shoes.length === 0 ? (
        <p>No shoes found in the database.</p>
      ) : (
        <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))' }}>
          {shoes.map((shoe) => (
            <div key={shoe.id} style={{ border: '1px solid #333', padding: '1rem', borderRadius: '8px', backgroundColor: '#1e1e1e' }}>
              <h2 style={{ fontSize: '1.2rem', marginBottom: '0.5rem', color: '#fff' }}>{shoe.name}</h2>
              <p style={{ color: '#aaa', margin: '0.2rem 0' }}>Brand: {shoe.brand || 'N/A'}</p>
              <p style={{ color: '#aaa', margin: '0.2rem 0' }}>Distance: {(shoe.distanceM / 1000).toFixed(2)} km</p>
              <p style={{ color: shoe.isActive ? '#4ade80' : '#f87171', margin: '0.2rem 0' }}>
                Status: {shoe.isActive ? 'Active' : 'Retired'}
              </p>
              <p style={{ color: '#888', fontSize: '0.8rem', marginTop: '1rem' }}>User: {shoe.user?.name || shoe.userId}</p>
              <p style={{ color: '#888', fontSize: '0.8rem' }}>Runs Tracking This Shoe: {shoe.runs.length}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
