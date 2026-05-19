import { createClient } from '@/utils/supabase/server'
import { cookies } from 'next/headers'

export default async function DashboardPage() {
  const cookieStore = await cookies()
  const supabase = createClient(cookieStore)

  const { data: homes } = await supabase.from('homes').select('id, name, address')

  return (
    <main style={{ padding: '2rem' }}>
      <h1>Kids Care Admin Dashboard</h1>
      <ul>
        {homes?.map((home) => (
          <li key={home.id}>{home.name}</li>
        ))}
      </ul>
    </main>
  )
}
