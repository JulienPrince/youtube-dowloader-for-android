// phone-frame.jsx — minimal Android-style device frame with themed status bar + nav.
// Wraps any screen content. Uses --bg / --text from active theme.

const PHONE_W = 412;
const PHONE_H = 892;

function Phone({ children, theme = 'light', density = 'cozy', accent = '#FF7A00', lang = 'fr', statusTime = '9:30', label }) {
  return (
    <div
      data-screen-label={label}
      className={`phone theme-${theme} density-${density}`}
      style={{
        '--accent': accent,
        width: PHONE_W,
        height: PHONE_H,
        borderRadius: 44,
        overflow: 'hidden',
        background: 'var(--bg)',
        boxShadow: '0 0 0 8px #111, 0 0 0 9px #2a2a2a, 0 30px 80px rgba(0,0,0,0.18)',
        position: 'relative',
      }}
    >
      <PhoneStatusBar time={statusTime} />
      <div style={{ flex: 1, position: 'relative', minHeight: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
      <PhoneNavBar />
    </div>
  );
}

function PhoneStatusBar({ time = '9:30' }) {
  return (
    <div style={{
      height: 36,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 24px',
      fontSize: 14, fontWeight: 500,
      color: 'var(--status-icon)',
      flexShrink: 0,
      position: 'relative',
      zIndex: 2,
    }}>
      <span>{time}</span>
      {/* punch hole */}
      <span style={{
        position: 'absolute', left: '50%', top: 10, transform: 'translateX(-50%)',
        width: 14, height: 14, borderRadius: '50%', background: '#111',
      }} />
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
        {/* signal */}
        <svg width="15" height="11" viewBox="0 0 15 11" fill="none">
          <path d="M0 9h2v2H0V9zm4-2h2v4H4V7zm4-3h2v7H8V4zm4-3h2v10h-2V1z" fill="currentColor"/>
        </svg>
        {/* wifi */}
        <svg width="14" height="11" viewBox="0 0 14 11" fill="none">
          <path d="M7 11l3-3.5a4.5 4.5 0 0 0-6 0L7 11z" fill="currentColor"/>
          <path d="M7 6.5l5-5.5a8.5 8.5 0 0 0-10 0l5 5.5z" fill="currentColor" opacity="0.4"/>
        </svg>
        {/* battery */}
        <svg width="22" height="11" viewBox="0 0 22 11" fill="none">
          <rect x="0.5" y="0.5" width="19" height="10" rx="2.5" stroke="currentColor" opacity="0.5"/>
          <rect x="2" y="2" width="13" height="7" rx="1" fill="currentColor"/>
          <rect x="20" y="3.5" width="1.5" height="4" rx="0.5" fill="currentColor" opacity="0.5"/>
        </svg>
      </span>
    </div>
  );
}

function PhoneNavBar() {
  return (
    <div style={{
      height: 24, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative', zIndex: 2,
    }}>
      <span style={{
        width: 120, height: 4, borderRadius: 999,
        background: 'var(--text)', opacity: 0.55,
      }} />
    </div>
  );
}

// Sheet / dialog primitives ---------------------------------------------------

function PhoneScrim({ children, onClose }) {
  return (
    <div
      onClick={onClose}
      style={{
        position: 'absolute', inset: 0, zIndex: 10,
        background: 'var(--scrim)',
        display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
        animation: 'scrim-in .15s ease',
      }}
    >
      <div onClick={(e) => e.stopPropagation()}>
        {children}
      </div>
    </div>
  );
}

function BottomSheet({ children, title, onClose }) {
  return (
    <div style={{
      background: 'var(--surface)',
      borderTopLeftRadius: 28, borderTopRightRadius: 28,
      paddingTop: 8, paddingBottom: 16,
      animation: 'sheet-in .22s cubic-bezier(.2,.7,.3,1)',
    }}>
      <div style={{
        width: 36, height: 4, borderRadius: 999,
        background: 'var(--border-2)',
        margin: '8px auto 4px',
      }} />
      {title && (
        <div style={{
          padding: '14px 24px 4px',
          fontSize: 20, fontWeight: 600, letterSpacing: '-0.01em',
        }}>{title}</div>
      )}
      {children}
    </div>
  );
}

// inject a couple keyframes once
if (typeof document !== 'undefined' && !document.getElementById('phone-anims')) {
  const s = document.createElement('style');
  s.id = 'phone-anims';
  s.textContent = `
    @keyframes scrim-in { from { background: rgba(0,0,0,0); } }
    @keyframes sheet-in { from { transform: translateY(40px); opacity: 0; } }
    @keyframes dialog-in { from { transform: scale(.96); opacity: 0; } }
  `;
  document.head.appendChild(s);
}

Object.assign(window, { Phone, PhoneStatusBar, PhoneNavBar, PhoneScrim, BottomSheet, PHONE_W, PHONE_H });
