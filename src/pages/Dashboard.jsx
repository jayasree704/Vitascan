import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import Sidebar from '../components/Sidebar';
import toast from 'react-hot-toast';
import { analyzeTestStripWithGemini } from '../lib/gemini';
import ReportActions from '../components/ReportActions';
import {
  BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell, Tooltip,
} from 'recharts';

/* ─── Helpers ──────────────────────────────────────────── */
function statusColor(level) {
  if (level < 20) return '#FFC0CB'; // Pale Pink
  if (level < 30) return '#FF69B4'; // Light Pink
  return '#C71585'; // Dark Pink
}
function statusLabel(level) {
  if (level < 20) return 'Deficient';
  if (level < 30) return 'Insufficient';
  return 'Sufficient';
}
function statusDesc(level) {
  if (level < 20) return 'Your levels are critically low. Immediate supplementation recommended.';
  if (level < 30) return 'Below optimal range. Lifestyle changes and supplementation advised.';
  return 'Your Vitamin D levels are within the healthy clinical range of 30–100 ng/mL.';
}
function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
const lifestyleTips = [
  'Expose arms and legs to direct sunlight for 15-20 minutes daily.',
  'Pair Vitamin D rich foods with healthy fats for optimal absorption.',
  'Retest your saliva Vitamin D levels in 8-12 weeks to monitor progress.',
];
const ranges = [
  { label: 'Deficient', range: '< 20 ng/mL', color: '#881337', bg: '#FFF0F5', swatch: '#FFC0CB', swatchLabel: 'Pale Pink Line T', tip: 'Seek medical attention. Supplement immediately.' },
  { label: 'Insufficient', range: '20–30 ng/mL', color: '#C71585', bg: '#FFF0F5', swatch: '#FF69B4', swatchLabel: 'Light Pink Line T', tip: 'Increase sun exposure and dietary intake.' },
  { label: 'Sufficient', range: '30–100 ng/mL', color: '#C71585', bg: '#FFF0F5', swatch: '#C71585', swatchLabel: 'Dark Pink Line T', tip: 'Maintain current lifestyle. Keep monitoring.' },
];

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
    lifestyle_tips: lifestyleTips,
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
    lifestyle_tips: lifestyleTips,
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
    lifestyle_tips: lifestyleTips,
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
    lifestyle_tips: lifestyleTips,
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
    lifestyle_tips: lifestyleTips,
    created_at: '2026-07-05T16:20:00Z',
    isSample: true,
  },
];

const STEP = { IDLE: 0, DETAILS: 1, ANALYZING: 2, RESULT: 3 };

export default function Dashboard() {
  const { user } = useAuth();
  const [scans, setScans] = useState([]);
  const [loading, setLoading] = useState(true);

  // Upload flow
  const [step, setStep] = useState(STEP.IDLE);
  const [preview, setPreview] = useState(null);
  const [file, setFile] = useState(null);
  const [result, setResult] = useState(null);
  const fileRef = useRef();

  // Patient details form state
  const [patient, setPatient] = useState({
    name: '', age: '', gender: 'Male',
    height: '', weight: '',
    healthConditions: '',
    collectionDate: new Date().toISOString().slice(0, 10),
    collectionTime: 'Morning',
    oralIntake: 'Fasted (>8 hrs)',
    oralHealth: 'Healthy',
  });

  const setP = (k) => (e) => setPatient(p => ({ ...p, [k]: e.target.value }));
  const bmi = () => {
    const h = parseFloat(patient.height) / 100;
    const w = parseFloat(patient.weight);
    return h > 0 && w > 0 ? (w / (h * h)).toFixed(1) : '–';
  };

  const fetchScans = async () => {
    setLoading(true);
    let remoteScans = [];
    try {
      let { data } = await supabase
        .from('scans')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      remoteScans = data || [];
    } catch (_) {}

    const localRaw = localStorage.getItem('vitascan_local_history');
    const localScans = localRaw ? JSON.parse(localRaw) : [];

    const combinedMap = new Map();
    [...localScans, ...remoteScans, ...FIXED_SAMPLE_SCANS].forEach(s => {
      const key = s.id || `${s.patient_name}_${s.created_at}`;
      if (!combinedMap.has(key)) {
        combinedMap.set(key, s);
      }
    });

    const combinedList = Array.from(combinedMap.values());
    combinedList.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    setScans(combinedList);
    setLoading(false);
  };
  useEffect(() => { fetchScans(); }, [user]);

  // Always show sample reference data on top dashboard card
  const sampleCard = FIXED_SAMPLE_SCANS[0];
  const level = 31.0;
  const color = statusColor(level);
  const label = 'Sample Data: Sufficient';
  const desc  = statusDesc(level);
  const trendData = [...scans].reverse().slice(-10).map((s, i) => ({
    name: `#${i + 1}`, level: s.vitamin_d_level, color: statusColor(s.vitamin_d_level),
  }));
  const displayName = user?.user_metadata?.full_name || user?.user_metadata?.name || user?.email?.split('@')[0] || 'there';

  /* ── File pick / drop ── */
  const handleFile = (f) => {
    if (!f) return;
    setFile(f);
    setResult(null);
    const reader = new FileReader();
    reader.onload = (ev) => { setPreview(ev.target.result); setStep(STEP.DETAILS); };
    reader.readAsDataURL(f);
  };
  const handleFileInput = (e) => handleFile(e.target.files?.[0]);
  const handleDrop = (e) => { e.preventDefault(); handleFile(e.dataTransfer.files?.[0]); };

  /* ── Analyze & Save ── */
  const handleAnalyze = async (e) => {
    e.preventDefault();
    if (!patient.name.trim()) { toast.error('Patient name is required'); return; }
    if (!patient.age) { toast.error('Patient age is required'); return; }

    setStep(STEP.ANALYZING);
    try {
      // Send uploaded image into real Google Gemini Vision AI API (gemini-3-flash-preview)
      const aiResult = await analyzeTestStripWithGemini(preview || file);

      const vitaminLevel = aiResult.level;
      const statusText = aiResult.status || statusLabel(vitaminLevel);
      const confidence = aiResult.confidence || 0.94;
      const tips = aiResult.lifestyleTips?.length > 0 ? aiResult.lifestyleTips : lifestyleTips;

      const isUuid = (id) =>
        typeof id === 'string' &&
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);

      const validUserId = isUuid(user?.id) ? user.id : null;

      const scanData = {
        ...(validUserId ? { user_id: validUserId } : {}),
        patient_name: patient.name.trim(),
        patient_age: parseInt(patient.age) || null,
        patient_gender: patient.gender,
        vitamin_d_level: vitaminLevel,
        status: statusText,
        ai_confidence: confidence,
        lifestyle_tips: tips,
        created_at: new Date().toISOString(),
      };

      let saved = null;
      try {
        let { data, error } = await supabase.from('scans').insert([scanData]).select().single();
        if (error) {
          const fallbackPayload = {
            ...(validUserId ? { user_id: validUserId } : {}),
            vitamin_d_level: vitaminLevel,
            status: statusText,
            ai_confidence: confidence,
          };
          const res = await supabase.from('scans').insert([fallbackPayload]).select().single();
          data = res.data;
        }
        saved = data;
      } catch (_) {
        // Fallback for offline or local session scans
      }

      const finalScanObj = {
        ...scanData,
        recommendations: aiResult.recommendations,
        measurements: aiResult.measurements,
        id: saved?.id || `scan_${Date.now()}`,
      };

      // Save to localStorage history so it persists across sessions & history tab
      const existingHistoryRaw = localStorage.getItem('vitascan_local_history');
      const existingHistory = existingHistoryRaw ? JSON.parse(existingHistoryRaw) : [];
      localStorage.setItem(
        'vitascan_local_history',
        JSON.stringify([finalScanObj, ...existingHistory])
      );

      setResult(finalScanObj);
      setScans(prev => [finalScanObj, ...prev]);
      setStep(STEP.RESULT);
      toast.success('Scan analysis complete & saved to history!');
    } catch (err) {
      toast.error('Scan error: ' + (err.message || 'Analysis failed'));
      setStep(STEP.DETAILS);
    }
  };

  const resetUpload = () => {
    setStep(STEP.IDLE); setPreview(null); setFile(null); setResult(null);
    setPatient({ name: '', age: '', gender: 'Male', height: '', weight: '', healthConditions: '',
      collectionDate: new Date().toISOString().slice(0, 10),
      collectionTime: 'Morning', oralIntake: 'Fasted (>8 hrs)', oralHealth: 'Healthy' });
    if (fileRef.current) fileRef.current.value = '';
  };

  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">

        {/* Header */}
        <div className="page-header">
          <div>
            <h1 className="page-title">{getGreeting()}</h1>
            <p className="page-subtitle">Welcome back, <strong>{displayName}</strong></p>
          </div>
          <button className="btn btn-icon btn-outline" onClick={fetchScans} title="Refresh">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" />
            </svg>
          </button>
        </div>

        {/* 2-Column Responsive Desktop Grid */}
        <div className="dashboard-grid">

          {/* ── LEFT COLUMN ── */}
          <div className="dash-col-main">

            {/* Vitamin D Status Card */}
            <div className="vd-card" style={{ '--card-color': color }}>
              <div className="vd-card-top">
                <div className="vd-card-left">
                  <div className="vd-badge" style={{ background: color + '22', color }}>{label}</div>
                  <div className="vd-level-wrap">
                    <span className="vd-level" style={{ color }}>{level.toFixed(1)}</span>
                    <span className="vd-unit">ng/mL</span>
                  </div>
                  <p className="vd-desc">{desc}</p>
                  <p className="vd-date">
                    Sample Reference Data
                  </p>
                </div>
                <div className="vd-card-right">
                  <svg viewBox="0 0 120 120" className="vd-gauge-svg">
                    <circle cx="60" cy="60" r="48" fill="none" stroke="#E0E2ED" strokeWidth="12" strokeLinecap="round" strokeDasharray="226 75" strokeDashoffset="-37" />
                    <circle cx="60" cy="60" r="48" fill="none" stroke={color} strokeWidth="12" strokeLinecap="round"
                      strokeDasharray={`${Math.min((level || 0) / 100 * 226, 226)} 301`} strokeDashoffset="-37"
                      style={{ transition: 'stroke-dasharray 1s ease' }} />
                    <text x="60" y="58" textAnchor="middle" fontSize="18" fontWeight="700" fill={color}>
                      {level.toFixed(0)}
                    </text>
                    <text x="60" y="72" textAnchor="middle" fontSize="9" fill="#717786">ng/mL</text>
                  </svg>
                </div>
              </div>
              <div className="vd-bar-wrap">
                <div className="vitamin-bar-track">
                  <div className="vitamin-bar-segment" style={{ background: '#FFC0CB', width: '33.3%' }} />
                  <div className="vitamin-bar-segment" style={{ background: '#FF69B4', width: '33.3%' }} />
                  <div className="vitamin-bar-segment" style={{ background: '#C71585', width: '33.4%' }} />
                  <div className="vitamin-bar-marker" style={{ left: `${Math.min((level / 60) * 100, 100)}%` }} />
                </div>
                <div className="vitamin-bar-labels">
                  <span style={{ color: '#881337' }}>Deficient</span>
                  <span style={{ color: '#C71585' }}>Insufficient</span>
                  <span style={{ color: '#C71585' }}>Sufficient</span>
                </div>
              </div>
            </div>

            {/* Upload + Patient Details Section */}
            <div className="section-card upload-section">
              <h2 className="section-title" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                Analyze Test Strip
              </h2>
              <p className="upload-hint">Upload a photo of your Vitamin D test strip for instant AI analysis.</p>

              {step === STEP.IDLE && (
                <div className="drop-zone" onDragOver={e => e.preventDefault()} onDrop={handleDrop} onClick={() => fileRef.current?.click()}>
                  <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFileInput} />
                  <div className="drop-icon" style={{ display: 'flex', justifyContent: 'center' }}>
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                      <circle cx="8.5" cy="8.5" r="1.5" />
                      <polyline points="21 15 16 10 5 21" />
                    </svg>
                  </div>
                  <p className="drop-title">Drop image here or click to browse</p>
                  <p className="drop-sub">Supports JPG, PNG, HEIC · Max 10 MB</p>
                  <button className="btn btn-primary" style={{ marginTop: 6, padding: '6px 20px', fontSize: 13 }}
                    onClick={e => { e.stopPropagation(); fileRef.current?.click(); }}>
                    Choose Image
                  </button>
                </div>
              )}

              {/* Patient Details Form */}
              {(step === STEP.DETAILS || step === STEP.ANALYZING) && (
                <div className="wizard-layout">
                  <div className="wizard-img-col">
                    <div className="upload-img-wrap">
                      <img src={preview} alt="Preview" className="upload-img" />
                      <button type="button" className="upload-clear-btn" onClick={resetUpload}>✕</button>
                    </div>
                    <div className="img-meta">
                      <span className="img-badge primary">CAPTURED SAMPLE</span>
                      <span className="img-badge dark">Stability: High</span>
                    </div>
                  </div>

                  <form className="patient-form" onSubmit={handleAnalyze}>
                    <div className="pf-section-label">ANALYSIS SUBJECT</div>
                    <div className="pf-section-title">Patient Details</div>

                    <div className="field-group">
                      <label className="field-label">Full Name *</label>
                      <div className="input-wrapper">
                        <input className="field-input" placeholder="e.g. John Doe" value={patient.name} onChange={setP('name')} required style={{ paddingLeft: 14 }} />
                      </div>
                    </div>

                    <div className="pf-row">
                      <div className="field-group" style={{ flex: 1 }}>
                        <label className="field-label">Age *</label>
                        <div className="input-wrapper">
                          <input className="field-input" type="number" min="1" max="120" placeholder="years" value={patient.age} onChange={setP('age')} required style={{ paddingLeft: 14 }} />
                        </div>
                      </div>
                      <div className="field-group" style={{ flex: 1 }}>
                        <label className="field-label">Gender</label>
                        <select className="field-select" value={patient.gender} onChange={setP('gender')}>
                          <option>Male</option><option>Female</option><option>Other</option>
                        </select>
                      </div>
                    </div>

                    <div className="field-group">
                      <label className="field-label">Existing Health Conditions</label>
                      <textarea className="field-input field-textarea" placeholder="Chronic illnesses, allergies, medications…"
                        value={patient.healthConditions} onChange={setP('healthConditions')} rows={2} />
                    </div>

                    <div className="pf-row">
                      <div className="field-group" style={{ flex: 1 }}>
                        <label className="field-label">Height (cm)</label>
                        <input className="field-input" type="number" placeholder="cm" value={patient.height} onChange={setP('height')} style={{ padding: '8px 12px' }} />
                      </div>
                      <div className="field-group" style={{ flex: 1 }}>
                        <label className="field-label">Weight (kg)</label>
                        <input className="field-input" type="number" placeholder="kg" value={patient.weight} onChange={setP('weight')} style={{ padding: '8px 12px' }} />
                      </div>
                      <div className="field-group" style={{ flex: 1 }}>
                        <label className="field-label">BMI</label>
                        <div className="bmi-display">{bmi()}</div>
                      </div>
                    </div>

                    <button type="submit" className="btn btn-primary btn-full" disabled={step === STEP.ANALYZING} style={{ marginTop: 4 }}>
                      {step === STEP.ANALYZING
                        ? <><span className="btn-spinner" /> Analyzing Saliva Test Strip…</>
                        : 'Check Details & Analyze'}
                    </button>
                  </form>
                </div>
              )}

              {/* Analysis Result */}
              {step === STEP.RESULT && result && (
                <div className="upload-preview-area">
                  <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start', flexWrap: 'wrap' }}>
                    {preview && <img src={preview} alt="Strip" className="upload-img" style={{ maxHeight: 120 }} />}
                    <div className="analysis-result" style={{ borderLeftColor: statusColor(result.vitamin_d_level), flex: 1, minWidth: 200 }}>
                      <div className="ar-header">
                        <div className="ar-level" style={{ color: statusColor(result.vitamin_d_level) }}>
                          {result.vitamin_d_level} <small>ng/mL</small>
                        </div>
                        <span className="hcard-badge" style={{ background: statusColor(result.vitamin_d_level) + '20', color: statusColor(result.vitamin_d_level) }}>
                          {result.status}
                        </span>
                      </div>
                      <div className="ar-patient-info">
                        <span>Patient: {result.patient_name}</span>
                        {result.patient_age && <span> · {result.patient_age} yrs</span>}
                      </div>
                      <p className="ar-desc">{statusDesc(result.vitamin_d_level)}</p>
                      <div className="ar-save-badge">✓ Saved to history</div>
                      <ReportActions scan={result} />
                      <div className="ar-actions" style={{ marginTop: 8 }}>
                        <button className="btn btn-outline" onClick={resetUpload} style={{ flex: 1, padding: '8px' }}>New Scan</button>
                        <Link to="/history" className="btn btn-primary" style={{ flex: 1, textDecoration: 'none', justifyContent: 'center', padding: '8px' }}>View History</Link>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* View Full History Banner (Bottom Left under Upload) */}
            <Link to="/history" className="history-banner">
              <div className="history-banner-icon">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
              </div>
              <div className="history-banner-text">
                <div className="history-banner-title">View Full History</div>
                <div className="history-banner-sub">{scans.length} tests recorded</div>
              </div>
              <span className="history-banner-arrow">›</span>
            </Link>

          </div>

          {/* ── RIGHT COLUMN (Sidebar stats & reference) ── */}
          <div className="dash-col-side">

            {/* Total Tests Card */}
            <div className="stat-card" style={{ padding: '8px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 3v11l-3 4.5A2 2 0 0 0 7.6 22h8.8a2 2 0 0 0 1.6-3.5L15 14V3" />
                  <line x1="8" y1="3" x2="16" y2="3" />
                </svg>
                <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--on-surface-var)' }}>Total Tests</span>
              </div>
              <span style={{ fontSize: 18, fontWeight: 800, color: 'var(--primary)' }}>{loading ? '…' : scans.length}</span>
            </div>

            {/* Trend Chart */}
            {trendData.length > 0 && (
              <div className="section-card">
                <h2 className="section-title" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="23 18 13.5 8.5 8.5 13.5 1 6" />
                    <polyline points="17 18 23 18 23 12" />
                  </svg>
                  Vitamin D Trend
                </h2>
                <ResponsiveContainer width="100%" height={110}>
                  <BarChart data={trendData} barCategoryGap="2%" margin={{ top: 4, right: 4, bottom: 0, left: -24 }}>
                    <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#717786' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: '#717786' }} axisLine={false} tickLine={false} />
                    <Tooltip formatter={(v) => [`${v.toFixed(1)} ng/mL`, 'Level']} contentStyle={{ borderRadius: 8, border: '1px solid #C1C6D7', fontSize: 11, padding: '4px 8px' }} />
                    <Bar dataKey="level" radius={[4, 4, 0, 0]} barSize={20}>
                      {trendData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}

            {/* Reference Guide */}
            <div className="section-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                <h2 className="section-title" style={{ display: 'flex', alignItems: 'center', gap: 6, margin: 0 }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
                  </svg>
                  Saliva Test Color Chart
                </h2>
                <span style={{ fontSize: 10, background: '#E8F5E9', color: '#2E7D32', padding: '2px 8px', borderRadius: 99, fontWeight: 700 }}>Line T Scale</span>
              </div>
              <div className="ref-grid side-ref-grid">
                {ranges.map((r) => (
                  <div key={r.label} className="ref-card" style={{ background: r.bg, borderColor: r.color + '40', padding: '10px 12px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div className="ref-label" style={{ color: r.color, fontWeight: 700 }}>{r.label}</div>
                      <div className="ref-range" style={{ color: r.color, fontWeight: 800 }}>{r.range}</div>
                    </div>
                    {/* Visual Color Swatch representing Line T color intensity */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '6px 0 4px 0', background: 'rgba(255,255,255,0.8)', padding: '4px 8px', borderRadius: 6, border: '1px solid rgba(0,0,0,0.06)' }}>
                      <div style={{ width: 14, height: 14, borderRadius: 3, background: r.swatch, border: '1px solid rgba(0,0,0,0.15)' }} />
                      <span style={{ fontSize: 10, fontWeight: 600, color: '#4A5568' }}>{r.swatchLabel}</span>
                    </div>
                    <p className="ref-tip" style={{ margin: 0 }}>{r.tip}</p>
                  </div>
                ))}
              </div>
            </div>

          </div>

        </div>

      </main>
    </div>
  );
}
