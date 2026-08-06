import { useAuth } from '../contexts/AuthContext';
import Sidebar from '../components/Sidebar';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

export default function Profile() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();

  const displayName = user?.user_metadata?.full_name || user?.user_metadata?.name || user?.email?.split('@')[0] || 'User';
  const email = user?.email || '–';
  const joined = user?.created_at
    ? new Date(user.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    : '–';
  const initials = displayName.charAt(0).toUpperCase();

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
    toast.success('Signed out');
  };

  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">

        {/* Profile Hero */}
        <div className="profile-hero">
          <div className="avatar-circle">{initials}</div>
          <div>
            <h1 className="profile-name">{displayName}</h1>
            <p className="profile-member">Member since {joined}</p>
          </div>
        </div>

        {/* Personal Info */}
        <div className="section-card">
          <h2 className="section-title">Personal Information</h2>
          <div className="info-list">
            <div className="info-row">
              <div className="info-meta">
                <span className="info-label">Full Name</span>
                <span className="info-value">{displayName}</span>
              </div>
              <span className="info-icon" style={{ display: 'flex', alignItems: 'center' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
                  <circle cx="12" cy="7" r="4" />
                </svg>
              </span>
            </div>

            <div className="info-row">
              <div className="info-meta">
                <span className="info-label">Email Address</span>
                <span className="info-value">{email}</span>
              </div>
              <span className="info-icon" style={{ display: 'flex', alignItems: 'center' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                  <polyline points="22,6 12,13 2,6" />
                </svg>
              </span>
            </div>

            <div className="info-row no-border">
              <div className="info-meta">
                <span className="info-label">Member Since</span>
                <span className="info-value">{joined}</span>
              </div>
              <span className="info-icon" style={{ display: 'flex', alignItems: 'center' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                  <line x1="16" y1="2" x2="16" y2="6" />
                  <line x1="8" y1="2" x2="8" y2="6" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
              </span>
            </div>
          </div>
        </div>

        {/* Account Settings & Notification Preferences */}
        <div className="section-card" style={{ marginTop: 16 }}>
          <h2 className="section-title">Account Settings</h2>
          <div className="info-list">
            <div
              className="info-row"
              style={{ cursor: 'pointer' }}
              onClick={async () => {
                if ('Notification' in window) {
                  const perm = await Notification.requestPermission();
                  if (perm === 'granted') {
                    toast.success('Notification permissions enabled!');
                  } else if (perm === 'denied') {
                    toast.error('Notifications blocked in browser settings. Please allow notifications in site permissions.');
                  } else {
                    toast('Notification status: ' + perm);
                  }
                } else {
                  toast.error('Notifications not supported in this browser');
                }
              }}
            >
              <div className="info-meta">
                <span className="info-label">Notification Preferences</span>
                <span className="info-value" style={{ fontSize: 12, color: 'var(--on-surface-var)' }}>Configure app push & lab reminder alerts</span>
              </div>
              <span className="info-icon" style={{ display: 'flex', alignItems: 'center' }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                  <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                </svg>
              </span>
            </div>
          </div>
        </div>

        {/* Sign Out */}
        <button className="btn btn-danger btn-full" onClick={handleSignOut} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
          Sign Out
        </button>
      </main>
    </div>
  );
}
