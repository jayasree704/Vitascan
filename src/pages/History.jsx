import { useEffect, useState, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import Sidebar from '../components/Sidebar';
import { downloadReportPDF, buildShareText } from '../lib/reportUtils';
import toast from 'react-hot-toast';
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell, Tooltip } from 'recharts';

function statusColor(level) {
  if (level < 20) return '#FFC0CB'; // Pale Pink (Deficient)
  if (level < 30) return '#FF69B4'; // Light Pink (Insufficient)
  return '#C71585'; // Dark Pink (Sufficient)
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
  const [shareOpen, setShareOpen] = useState(false);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleDownload = async () => {
    if (!selected) return;
    setPdfLoading(true);
    try {
      downloadReportPDF(selected);
      toast.success('Report downloaded!');
    } catch (err) {
      toast.error('Failed to generate PDF: ' + err.message);
    } finally {
      setPdfLoading(false);
    }
  };

  const handleCopy = async () => {
    if (!selected) return;
    try {
      await navigator.clipboard.writeText(buildShareText(selected));
      setCopied(true);
      toast.success('Report text copied!');
      setTimeout(() => setCopied(false), 2500);
    } catch {
      toast.error('Could not copy to clipboard.');
    }
  };

  const handleNativeShare = async () => {
    if (!selected) return;
    if (navigator.share) {
      try { await navigator.share({ title: 'VitaScan Report', text: buildShareText(selected) }); }
      catch { /* user cancelled */ }
    } else {
      setShareOpen(true);
    }
  };

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

  useEffect(() => {
    if (scans.length > 0) {
      const params = new URLSearchParams(window.location.search);
      const reportId = params.get('report');
      if (reportId) {
        const found = scans.find(s => String(s.id) === String(reportId));
        if (found) {
          setSelected(found);
        }
      }
    }
  }, [scans]);

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
                    const c = statusColor(scan.vitamin_d_level);
                    const meta = [scan.patient_age ? `${scan.patient_age} yrs` : '', scan.patient_gender || ''].filter(Boolean).join(' · ');
                    return (
                      <div key={scan.id} className="history-card" style={{ borderLeftColor: c, padding: '8px 12px' }} onClick={() => setSelected(scan)}>
                        <div className="hcard-circle" style={{ background: c + '18', width: 42, height: 42 }}>
                          <div className="hcard-level" style={{ color: c, fontSize: 13 }}>{scan.vitamin_d_level.toFixed(1)}</div>
                          <div className="hcard-unit" style={{ fontSize: 8 }}>ng/mL</div>
                        </div>
                        <div className="hcard-body">
                          <div className="hcard-row" style={{ marginBottom: 2 }}>
                            <span className="hcard-name" style={{ fontSize: 13 }}>{scan.patient_name || 'Patient'}</span>
                            <span className="hcard-badge" style={{ background: c + '18', color: c, fontSize: 9, padding: '2px 6px' }}>{scan.status}</span>
                          </div>
                          {meta && <div className="hcard-meta" style={{ fontSize: 10, marginBottom: 1 }}>{meta}</div>}
                          <div className="hcard-date" style={{ fontSize: 10 }}>{fmt(scan.created_at)}</div>
                        </div>
                        <span className="hcard-arrow" style={{ color: c, fontSize: 16 }}>›</span>
                      </div>
                    );
                  })}
                </div>
              )}

            </div>
          </div>

        </div>

        {selected && (
          <div className="modal-overlay" onClick={() => setSelected(null)}>
            <div className="modal-card" onClick={e => e.stopPropagation()}>

              {/* ── Scrollable content ── */}
              <div className="modal-scroll-body">
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
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#34C759" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                          <polyline points="20 6 9 17 4 12" />
                        </svg>
                        {tip}
                      </div>
                    ))}
                  </div>
                )}
              {/* Action Buttons: Download & Share Report */}
              <div style={{ display: 'flex', gap: 10, marginTop: 20, paddingTop: 16, borderTop: '1px solid #E0E2ED' }}>
                <button className="modal-btn-dl" onClick={handleDownload} disabled={pdfLoading}>
                  {pdfLoading ? (
                    <><span className="btn-spinner" style={{ width: 14, height: 14 }} /> Generating…</>
                  ) : (
                    <>
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                        <polyline points="7 10 12 15 17 10" />
                        <line x1="12" y1="15" x2="12" y2="3" />
                      </svg>
                      Download Report
                    </>
                  )}
                </button>
                <button className="modal-btn-share" onClick={handleNativeShare}>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                  </svg>
                  Share Report
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

        {/* ── Share Sheet Modal ── */}
        {shareOpen && selected && (() => {
          const shareText = buildShareText(selected);
          const waUrl = `https://wa.me/?text=${encodeURIComponent(shareText)}`;
          const smsUrl = `sms:?body=${encodeURIComponent(shareText)}`;
          const emailUrl = `mailto:?subject=${encodeURIComponent('VitaScan Vitamin D Report')}&body=${encodeURIComponent(shareText)}`;
          const tgUrl = `https://t.me/share/url?url=${encodeURIComponent(window.location.href)}&text=${encodeURIComponent('VitaScan Vitamin D Report')}`;
          return (
            <div className="share-overlay" onClick={() => setShareOpen(false)}>
              <div className="share-modal" onClick={e => e.stopPropagation()}>
                <div className="share-modal-header">
                  <div className="share-modal-title">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                      <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                      <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                    </svg>
                    Share Report
                  </div>
                  <button className="share-modal-close" onClick={() => setShareOpen(false)}>✕</button>
                </div>
                <p className="share-modal-sub">Send this Vitamin D result via your preferred app</p>
                <div className="share-apps-grid">

                  {/* WhatsApp */}
                  <a href={waUrl} target="_blank" rel="noopener noreferrer" className="share-app-btn share-wa">
                    <svg viewBox="0 0 32 32" className="share-app-icon">
                      <circle cx="16" cy="16" r="16" fill="#25D366" />
                      <path fill="#fff" d="M23.5 8.5A10.4 10.4 0 0 0 16 5.5C10.2 5.5 5.5 10.2 5.5 16c0 1.8.5 3.6 1.4 5.2L5.5 26.5l5.5-1.4a10.5 10.5 0 0 0 5 1.3c5.8 0 10.5-4.7 10.5-10.5 0-2.8-1.1-5.4-3-7.4zm-7.5 16.1a8.7 8.7 0 0 1-4.5-1.2l-.3-.2-3.3.9.9-3.2-.2-.3A8.7 8.7 0 0 1 7.3 16a8.7 8.7 0 1 1 17.4 0 8.7 8.7 0 0 1-8.7 8.6zm4.8-6.5c-.3-.1-1.6-.8-1.8-.9-.2-.1-.4-.1-.5.1-.2.2-.6.9-.8 1-.1.2-.3.2-.5.1-.3-.1-1.1-.4-2.1-1.3-.8-.7-1.3-1.5-1.4-1.8-.1-.3 0-.4.1-.5l.4-.4.2-.4v-.4l-.9-2.1c-.2-.5-.5-.5-.6-.5h-.5c-.2 0-.5.1-.7.3-.3.3-1 1-1 2.4s1 2.7 1.2 2.9c.2.3 2 3 4.8 4.2.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.5-.1 1.6-.7 1.8-1.3.2-.6.2-1.2.1-1.3-.1-.2-.2-.2-.5-.3z"/>
                    </svg>
                    <span>WhatsApp</span>
                  </a>

                  {/* SMS */}
                  <a href={smsUrl} className="share-app-btn share-sms">
                    <svg viewBox="0 0 32 32" className="share-app-icon">
                      <circle cx="16" cy="16" r="16" fill="#007AFF" />
                      <path fill="#fff" d="M8 8h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H11l-5 4V10a2 2 0 0 1 2-2z" />
                    </svg>
                    <span>SMS</span>
                  </a>

                  {/* Email */}
                  <a href={emailUrl} className="share-app-btn share-email">
                    <svg viewBox="0 0 32 32" className="share-app-icon">
                      <circle cx="16" cy="16" r="16" fill="#EA4335" />
                      <path fill="#fff" d="M7 10l9 7 9-7V22H7V10zm0 0l9 7 9-7" />
                    </svg>
                    <span>Email</span>
                  </a>

                  {/* Telegram */}
                  <a href={tgUrl} target="_blank" rel="noopener noreferrer" className="share-app-btn share-telegram">
                    <svg viewBox="0 0 32 32" className="share-app-icon">
                      <circle cx="16" cy="16" r="16" fill="#2CA5E0" />
                      <path fill="#fff" d="M7 15.7l4.5 1.7 1.7 5.5 2.7-3.2 4.9 3.8 3.7-15.5L7 15.7zm5.1.7 8.8-5.5-5.9 6.8-.3 3-2.6-4.3z"/>
                    </svg>
                    <span>Telegram</span>
                  </a>

                  {/* Copy */}
                  <button className="share-app-btn share-copy" onClick={handleCopy}>
                    <div className="share-copy-circle">
                      {copied
                        ? <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>
                        : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" /><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" /></svg>}
                    </div>
                    <span>{copied ? 'Copied!' : 'Copy Text'}</span>
                  </button>

                  {/* Native Share */}
                  {typeof navigator !== 'undefined' && !!navigator.share && (
                    <button className="share-app-btn share-native" onClick={handleNativeShare}>
                      <div className="share-native-circle">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                          <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                          <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                        </svg>
                      </div>
                      <span>More…</span>
                    </button>
                  )}

                </div>
              </div>
            </div>
          );
        })()}
      </main>
    </div>
  );
}
