import { useEffect, useState, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import Sidebar from '../components/Sidebar';
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell, Tooltip } from 'recharts';
import { downloadReportPDF, shareReport } from '../lib/pdfGenerator';

function statusColor(level) {
  if (level < 20) return '#F472B6'; // Pale Pink (Deficient)
  if (level < 30) return '#EC4899'; // Light Pink (Insufficient)
  return '#BE185D';                 // Dark Pink (Sufficient)
}

function fmt(dt) {
  return new Date(dt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

const FIXED_SAMPLE_SCANS = [
  {
    id: 'sample-1',
    user_id: 'sample',
    patient_name: 'Jagadishwar Reddy',
    patient_age: 26,
    patient_gender: 'Male',
    vitamin_d_level: 31.0,
    status: 'Sufficient',
    ai_confidence: 0.94,
    lifestyle_tips: ['Expose arms and legs to direct sunlight for 15-20 minutes daily.'],
    created_at: '2026-07-24T08:30:00Z',
    isSample: true,
  },
  {
    id: 'sample-2',
    user_id: 'sample',
    patient_name: 'Sample Patient A',
    patient_age: 30,
    patient_gender: 'Female',
    vitamin_d_level: 31.0,
    status: 'Sufficient',
    ai_confidence: 0.94,
    lifestyle_tips: ['Pair Vitamin D rich foods with healthy fats.'],
    created_at: '2026-07-20T14:15:00Z',
    isSample: true,
  },
  {
    id: 'sample-3',
    user_id: 'sample',
    patient_name: 'Sample Patient B',
    patient_age: 45,
    patient_gender: 'Male',
    vitamin_d_level: 31.0,
    status: 'Sufficient',
    ai_confidence: 0.94,
    lifestyle_tips: ['Retest your levels in 8-12 weeks.'],
    created_at: '2026-07-15T09:10:00Z',
    isSample: true,
  },
  {
    id: 'sample-4',
    user_id: 'sample',
    patient_name: 'Sample Patient C',
    patient_age: 22,
    patient_gender: 'Female',
    vitamin_d_level: 31.0,
    status: 'Sufficient',
    ai_confidence: 0.94,
    lifestyle_tips: ['Maintain optimal sunlight exposure.'],
    created_at: '2026-07-10T11:45:00Z',
    isSample: true,
  },
  {
    id: 'sample-5',
    user_id: 'sample',
    patient_name: 'Sample Patient D',
    patient_age: 35,
    patient_gender: 'Male',
    vitamin_d_level: 31.0,
    status: 'Sufficient',
    ai_confidence: 0.94,
    lifestyle_tips: ['Keep monitoring regularly.'],
    created_at: '2026-07-05T16:20:00Z',
    isSample: true,
  },
];

export default function History() {
  const { user } = useAuth();
  const [scans, setScans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState(null);

  const fetchScans = async () => {
    setLoading(true);
    let { data } = await supabase
      .from('scans')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    if (!data || data.length === 0) {
      const res = await supabase
        .from('scans')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      data = res.data;
    }
    setScans(data && data.length > 0 ? data : FIXED_SAMPLE_SCANS);
    setLoading(false);
  };

  useEffect(() => { fetchScans(); }, [user]);

  const filtered = useMemo(() => {
    if (!search) return scans;
    const q = search.toLowerCase();
    return scans.filter(s =>
      (s.patient_name || '').toLowerCase().includes(q) ||
      (s.status || '').toLowerCase().includes(q)
    );
  }, [scans, search]);

  const trendData = [...scans].reverse().slice(-10).map((s, i) => ({
    name: `#${i + 1}`,
    level: s.vitamin_d_level,
    color: statusColor(s.vitamin_d_level),
  }));

  const latest = scans[0];

  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">
        {/* Header */}
        <div className="page-header">
          <div>
            <h1 className="page-title">Scan History</h1>
            <p className="page-subtitle">Your complete Vitamin D test records</p>
          </div>
          <button className="btn btn-icon btn-outline" onClick={fetchScans} title="Refresh">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" />
            </svg>
          </button>
        </div>

        {/* 2-Column Equal Size Grid (Left: Analytics, Right: Scrollable Records Card) */}
        <div className="history-grid">

          {/* ── LEFT COLUMN: Analytics Card (Same size as Right) ── */}
          <div className="history-col-analytics">

            {/* Stat Cards */}
            <div className="stats-grid" style={{ gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
              <div className="stat-card" style={{ padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 3v11l-3 4.5A2 2 0 0 0 7.6 22h8.8a2 2 0 0 0 1.6-3.5L15 14V3" />
                  <line x1="8" y1="3" x2="16" y2="3" />
                </svg>
                <div style={{ textAlign: 'left' }}>
                  <div style={{ fontSize: 10, color: 'var(--on-surface-var)', fontWeight: 600 }}>TOTAL SCANS</div>
                  <div style={{ fontSize: 18, fontWeight: 800, color: 'var(--primary)' }}>{loading ? '…' : scans.length}</div>
                </div>
              </div>

              <div className="stat-card" style={{ padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={latest ? statusColor(latest.vitamin_d_level) : 'var(--primary)'} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" />
                </svg>
                <div style={{ textAlign: 'left' }}>
                  <div style={{ fontSize: 10, color: 'var(--on-surface-var)', fontWeight: 600 }}>LATEST LEVEL</div>
                  <div style={{ fontSize: 18, fontWeight: 800, color: latest ? statusColor(latest.vitamin_d_level) : 'var(--primary)' }}>
                    {latest ? `${latest.vitamin_d_level.toFixed(1)}` : '–'} <small style={{ fontSize: 10, fontWeight: 400 }}>ng/mL</small>
                  </div>
                </div>
              </div>
            </div>

            {/* Vitamin D Trend Chart */}
            {trendData.length > 0 && (
              <div className="section-card" style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <h2 className="section-title" style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, marginBottom: 8 }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="23 18 13.5 8.5 8.5 13.5 1 6" />
                    <polyline points="17 18 23 18 23 12" />
                  </svg>
                  Vitamin D Trend
                </h2>
                <div style={{ flex: 1, minHeight: 180 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={trendData} barCategoryGap="2%" margin={{ top: 8, right: 8, bottom: 0, left: -24 }}>
                      <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#717786' }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fontSize: 10, fill: '#717786' }} axisLine={false} tickLine={false} />
                      <Tooltip
                        formatter={(v) => [`${v.toFixed(1)} ng/mL`, 'Level']}
                        cursor={{ fill: 'rgba(0, 88, 188, 0.04)', rx: 4 }}
                        contentStyle={{ borderRadius: 8, border: '1px solid #C1C6D7', fontSize: 11, padding: '4px 8px' }}
                      />
                      <Bar dataKey="level" radius={[4, 4, 0, 0]} barSize={22}>
                        {trendData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}

          </div>

          {/* ── RIGHT COLUMN: History Details Card with Internal Scrolling (Same Size) ── */}
          <div className="history-col-details">
            <div className="history-records-card">

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <h2 className="section-title" style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, margin: 0 }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                    <polyline points="14 2 14 8 20 8" />
                    <line x1="16" y1="13" x2="8" y2="13" />
                    <line x1="16" y1="17" x2="8" y2="17" />
                  </svg>
                  Patient Records ({filtered.length})
                </h2>
              </div>

              {/* Search input inside card */}
              <div className="search-wrapper">
                <span className="search-icon" style={{ display: 'flex', alignItems: 'center' }}>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--outline)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="11" cy="11" r="8" />
                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                  </svg>
                </span>
                <input className="search-input" placeholder="Search patient by name or status…"
                  value={search} onChange={e => setSearch(e.target.value)} style={{ padding: '7px 32px 7px 34px', fontSize: 12 }} />
                {search && <button className="search-clear" onClick={() => setSearch('')}>✕</button>}
              </div>

              {/* History Cards List - Internal Scrollable Area */}
              {loading ? (
                <div className="loading-state" style={{ padding: 20 }}><div className="spinner" /><p>Loading records…</p></div>
              ) : filtered.length === 0 ? (
                <div className="empty-state" style={{ padding: 20 }}>
                  <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="var(--outline-var)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: 6 }}>
                    <path d="M9 3v11l-3 4.5A2 2 0 0 0 7.6 22h8.8a2 2 0 0 0 1.6-3.5L15 14V3" />
                    <line x1="8" y1="3" x2="16" y2="3" />
                  </svg>
                  <p style={{ fontSize: 12 }}>{search ? `No records matching "${search}"` : 'No scan records yet'}</p>
                </div>
              ) : (
                <div className="history-scroll-list">
                  {filtered.map((scan) => {
                    const level = scan.vitamin_d_level != null ? Number(scan.vitamin_d_level) : 0;
                    const c = statusColor(level);
                    const name = (scan.patient_name && String(scan.patient_name).trim()) ? String(scan.patient_name).trim() : 'Patient Record';
                    const ageStr = scan.patient_age ? `${scan.patient_age} yrs` : '';
                    const genderStr = scan.patient_gender || '';
                    const metaStr = [ageStr, genderStr].filter(Boolean).join(' · ');
                    const displayMeta = metaStr || 'Vitamin D Analysis';
                    const statusText = scan.status || (level < 20 ? 'Deficient' : level < 30 ? 'Insufficient' : 'Sufficient');

                    return (
                      <div key={scan.id || Math.random()} className="history-card" style={{ borderLeftColor: c }} onClick={() => setSelected(scan)}>
                        <div className="hcard-circle" style={{ background: c + '18' }}>
                          <div className="hcard-level" style={{ color: c }}>{level.toFixed(1)}</div>
                          <div className="hcard-unit">ng/mL</div>
                        </div>
                        <div className="hcard-body">
                          <div className="hcard-row">
                            <span className="hcard-name">{name}</span>
                            <span className="hcard-badge" style={{ background: c + '18', color: c, padding: '2px 8px', fontSize: '10px' }}>{statusText}</span>
                          </div>
                          <div className="hcard-meta">{displayMeta}</div>
                          <div className="hcard-date">{fmt(scan.created_at || new Date())}</div>
                        </div>
                        <span className="hcard-arrow" style={{ color: c }}>›</span>
                      </div>
                    );
                  })}
                </div>
              )}

            </div>
          </div>

        </div>

        {/* Detail Modal */}
        {selected && (
          <div className="modal-overlay" onClick={() => setSelected(null)}>
            <div className="modal-card" onClick={e => e.stopPropagation()}>
              <button className="modal-close" onClick={() => setSelected(null)}>✕</button>
              <div className="modal-header" style={{ borderLeftColor: statusColor(selected.vitamin_d_level) }}>
                <div className="modal-level" style={{ color: statusColor(selected.vitamin_d_level) }}>
                  {selected.vitamin_d_level.toFixed(1)} <small>ng/mL</small>
                </div>
                <span className="hcard-badge" style={{ background: statusColor(selected.vitamin_d_level) + '18', color: statusColor(selected.vitamin_d_level) }}>
                  {selected.status}
                </span>
              </div>
              <div className="modal-body">
                {selected.patient_name && <div className="modal-row"><span>Patient</span><strong>{selected.patient_name}</strong></div>}
                {selected.patient_age && <div className="modal-row"><span>Age</span><strong>{selected.patient_age} yrs</strong></div>}
                {selected.patient_gender && <div className="modal-row"><span>Gender</span><strong>{selected.patient_gender}</strong></div>}
                <div className="modal-row"><span>Date</span><strong>{fmt(selected.created_at)}</strong></div>
                <div className="modal-row"><span>AI Confidence</span><strong>{((selected.ai_confidence || 0.94) * 100).toFixed(0)}%</strong></div>
              </div>
              {selected.lifestyle_tips?.length > 0 && (
                <div className="modal-tips">
                  <h4>Lifestyle Tips</h4>
                  {selected.lifestyle_tips.map((tip, i) => (
                    <div key={i} className="tip-row" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#BE185D" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <polyline points="20 6 9 17 4 12" />
                      </svg>
                      {tip}
                    </div>
                  ))}
                </div>
              )}

              {/* Share & Download Action Buttons */}
              <div className="modal-actions" style={{ display: 'flex', gap: 10, marginTop: 20, paddingTop: 16, borderTop: '1px solid #E2E8F0', flexWrap: 'wrap' }}>
                <button
                  className="btn btn-outline"
                  style={{ flex: 1, minWidth: 120, padding: '10px 14px', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, fontSize: 13, fontWeight: 600, color: '#2563EB', borderColor: '#BFDBFE', background: '#EFF6FF' }}
                  onClick={() => shareReport(selected)}
                  title="Share Report Summary"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="18" cy="5" r="3" />
                    <circle cx="6" cy="12" r="3" />
                    <circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  Share
                </button>

                <button
                  className="btn btn-primary"
                  style={{ flex: 1, minWidth: 120, padding: '10px 14px', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, fontSize: 13, fontWeight: 600, background: 'linear-gradient(135deg, #0058BC, #1D4ED8)' }}
                  onClick={() => downloadReportPDF(selected)}
                  title="Download Report PDF"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="7 10 12 15 17 10" />
                    <line x1="12" y1="15" x2="12" y2="3" />
                  </svg>
                  Download PDF
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
