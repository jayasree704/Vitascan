import { useState } from 'react';
import toast from 'react-hot-toast';
import { downloadReportPDF, buildShareText } from '../lib/reportUtils';

/**
 * ReportActions — Download PDF + Share buttons.
 * Drop anywhere after a scan result is available.
 *
 * Props:
 *   scan     {object}  The scan result object
 *   compact  {boolean} If true, renders smaller icon-only style buttons
 */
export default function ReportActions({ scan, compact = false }) {
  const [shareOpen, setShareOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [pdfLoading, setPdfLoading] = useState(false);

  /* ── Download PDF ── */
  const handleDownload = async () => {
    setPdfLoading(true);
    try {
      downloadReportPDF(scan);
      toast.success('Report downloaded!');
    } catch (err) {
      toast.error('Failed to generate PDF: ' + err.message);
    } finally {
      setPdfLoading(false);
    }
  };

  /* ── Share helpers ── */
  const shareText = buildShareText(scan);
  const waUrl = `https://wa.me/?text=${encodeURIComponent(shareText)}`;

  const handleNativeShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'VitaScan Report',
          text: shareText,
        });
      } catch {
        // user cancelled — no error toast needed
      }
    } else {
      setShareOpen(true);
    }
  };

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(shareText);
      setCopied(true);
      toast.success('Report text copied!');
      setTimeout(() => setCopied(false), 2500);
    } catch {
      toast.error('Could not copy to clipboard.');
    }
  };

  /* ── SMS share ── */
  const smsUrl = `sms:?body=${encodeURIComponent(shareText)}`;

  /* ── Email share ── */
  const subject = encodeURIComponent('VitaScan Vitamin D Report');
  const body = encodeURIComponent(shareText);
  const emailUrl = `mailto:?subject=${subject}&body=${body}`;

  if (compact) {
    return (
      <div className="ra-compact">
        <button
          className="ra-icon-btn ra-pdf"
          onClick={handleDownload}
          disabled={pdfLoading}
          title="Download PDF Report"
        >
          {pdfLoading
            ? <span className="btn-spinner" style={{ width: 14, height: 14 }} />
            : (
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
            )}
          PDF
        </button>
        <button
          className="ra-icon-btn ra-share"
          onClick={() => setShareOpen(true)}
          title="Share Report"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
            <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
            <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
          </svg>
          Share
        </button>

        {shareOpen && (
          <ShareModal
            shareText={shareText}
            waUrl={waUrl}
            smsUrl={smsUrl}
            emailUrl={emailUrl}
            copied={copied}
            onCopy={handleCopy}
            onNativeShare={handleNativeShare}
            onClose={() => setShareOpen(false)}
          />
        )}
      </div>
    );
  }

  return (
    <div className="ra-row">
      {/* Download PDF */}
      <button className="btn btn-report-dl" onClick={handleDownload} disabled={pdfLoading}>
        {pdfLoading ? (
          <><span className="btn-spinner" /> Generating…</>
        ) : (
          <>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            Download PDF
          </>
        )}
      </button>

      {/* Share */}
      <button className="btn btn-report-share" onClick={() => setShareOpen(true)}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
          <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
          <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
        </svg>
        Share Report
      </button>

      {shareOpen && (
        <ShareModal
          shareText={shareText}
          waUrl={waUrl}
          smsUrl={smsUrl}
          emailUrl={emailUrl}
          copied={copied}
          onCopy={handleCopy}
          onNativeShare={handleNativeShare}
          onClose={() => setShareOpen(false)}
        />
      )}
    </div>
  );
}

/* ────────────────────────────────────────────────────────── */
/* Share Modal                                               */
/* ────────────────────────────────────────────────────────── */
function ShareModal({ waUrl, smsUrl, emailUrl, copied, onCopy, onNativeShare, onClose }) {
  const hasNativeShare = typeof navigator !== 'undefined' && !!navigator.share;

  return (
    <div className="share-overlay" onClick={onClose}>
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
          <button className="share-modal-close" onClick={onClose}>✕</button>
        </div>

        <p className="share-modal-sub">Send this Vitamin D result via your preferred app</p>

        <div className="share-apps-grid">

          {/* WhatsApp */}
          <a
            href={waUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="share-app-btn share-wa"
          >
            <svg viewBox="0 0 32 32" className="share-app-icon">
              <circle cx="16" cy="16" r="16" fill="#25D366" />
              <path fill="#fff" d="M23.5 8.5A10.4 10.4 0 0 0 16 5.5C10.2 5.5 5.5 10.2 5.5 16c0 1.8.5 3.6 1.4 5.2L5.5 26.5l5.5-1.4a10.5 10.5 0 0 0 5 1.3c5.8 0 10.5-4.7 10.5-10.5 0-2.8-1.1-5.4-3-7.4zm-7.5 16.1a8.7 8.7 0 0 1-4.5-1.2l-.3-.2-3.3.9.9-3.2-.2-.3A8.7 8.7 0 0 1 7.3 16a8.7 8.7 0 1 1 17.4 0 8.7 8.7 0 0 1-8.7 8.6zm4.8-6.5c-.3-.1-1.6-.8-1.8-.9-.2-.1-.4-.1-.5.1-.2.2-.6.9-.8 1-.1.2-.3.2-.5.1-.3-.1-1.1-.4-2.1-1.3-.8-.7-1.3-1.5-1.4-1.8-.1-.3 0-.4.1-.5l.4-.4.2-.4v-.4l-.9-2.1c-.2-.5-.5-.5-.6-.5h-.5c-.2 0-.5.1-.7.3-.3.3-1 1-1 2.4s1 2.7 1.2 2.9c.2.3 2 3 4.8 4.2.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.5-.1 1.6-.7 1.8-1.3.2-.6.2-1.2.1-1.3-.1-.2-.2-.2-.5-.3z"/>
            </svg>
            <span>WhatsApp</span>
          </a>

          {/* SMS */}
          <a
            href={smsUrl}
            className="share-app-btn share-sms"
          >
            <svg viewBox="0 0 32 32" className="share-app-icon">
              <circle cx="16" cy="16" r="16" fill="#007AFF" />
              <path fill="#fff" d="M8 8h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H11l-5 4V10a2 2 0 0 1 2-2z" />
            </svg>
            <span>SMS</span>
          </a>

          {/* Email */}
          <a
            href={emailUrl}
            className="share-app-btn share-email"
          >
            <svg viewBox="0 0 32 32" className="share-app-icon">
              <circle cx="16" cy="16" r="16" fill="#EA4335" />
              <path fill="#fff" d="M7 10l9 7 9-7V22H7V10zm0 0l9 7 9-7" />
            </svg>
            <span>Email</span>
          </a>

          {/* Telegram */}
          <a
            href={`https://t.me/share/url?url=${encodeURIComponent(window.location.href)}&text=${encodeURIComponent(buildShareTextShort())}`}
            target="_blank"
            rel="noopener noreferrer"
            className="share-app-btn share-telegram"
          >
            <svg viewBox="0 0 32 32" className="share-app-icon">
              <circle cx="16" cy="16" r="16" fill="#2CA5E0" />
              <path fill="#fff" d="M7 15.7l4.5 1.7 1.7 5.5 2.7-3.2 4.9 3.8 3.7-15.5L7 15.7zm5.1.7 8.8-5.5-5.9 6.8-.3 3-2.6-4.3z"/>
            </svg>
            <span>Telegram</span>
          </a>

          {/* Copy Link */}
          <button className="share-app-btn share-copy" onClick={onCopy}>
            <div className="share-copy-circle">
              {copied
                ? (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                )
                : (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="9" y="9" width="13" height="13" rx="2" /><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                  </svg>
                )}
            </div>
            <span>{copied ? 'Copied!' : 'Copy Text'}</span>
          </button>

          {/* Native Share (if supported) */}
          {hasNativeShare && (
            <button className="share-app-btn share-native" onClick={onNativeShare}>
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
}

function buildShareTextShort() {
  return 'VitaScan Vitamin D Report';
}
