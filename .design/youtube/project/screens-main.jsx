// screens-main.jsx — main WebView screen + interactive download flow.

const SAMPLE_VIDEO = {
  title: "Live coding: building a minimal Flutter UI in 2026",
  channel: "Marc Pajak",
  views: "184 k",
  age: "il y a 3 jours",
  // playlist context
  inPlaylist: true,
  playlistTitle: "Flutter from scratch · 2026",
  playlistCount: 12,
  playlistIndex: 4,
};

const UP_NEXT = [
  { t: "Material 3 expressive — what changed", ch: "Flutter", dur: "12:04", color: '#FFB8B8' },
  { t: "Riverpod 3 in 14 minutes",              ch: "Code with Andrea", dur: "14:21", color: '#B8D8FF' },
  { t: "FFmpeg on Android: the missing manual", ch: "Native Things", dur: "22:47", color: '#FFE08A' },
  { t: "WebView vs custom shell, the trade-offs",ch: "Marc Pajak", dur: "08:55", color: '#C8F5C0' },
];

const PLAYLIST_VIDEOS = [
  { t: "Intro & setup",                  dur: "06:12", ix: 1 },
  { t: "Project structure that scales",  dur: "11:30", ix: 2 },
  { t: "Theming & dark mode",            dur: "14:08", ix: 3 },
  { t: "Live coding: minimal UI 2026",   dur: "18:42", ix: 4, current: true },
  { t: "State management without tears", dur: "21:55", ix: 5 },
  { t: "Networking & error states",      dur: "16:20", ix: 6 },
];

// ─────────────────────────────────────────────────────────────────────────────
// Mocked YouTube WebView page
// ─────────────────────────────────────────────────────────────────────────────
function YouTubeMock({ t, theme }) {
  return (
    <div style={{
      background: 'var(--bg)', color: 'var(--text)',
      flex: 1, overflow: 'auto',
      paddingBottom: 96,
    }}>
      {/* Top YouTube bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '8px 14px 10px',
        background: 'var(--bg)', position: 'sticky', top: 0, zIndex: 1,
      }}>
        <YouTubeLogo />
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, color: 'var(--text)' }}>
          <ISearch size={22} stroke={1.8} />
          <IBell size={22} stroke={1.8} />
          <div style={{
            width: 26, height: 26, borderRadius: '50%',
            background: '#FF7A8A', color: 'white',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 600,
          }}>M</div>
        </div>
      </div>

      {/* Video player */}
      <div style={{
        width: '100%', aspectRatio: '16 / 9',
        background: 'linear-gradient(135deg, #1a1f2e 0%, #2a3145 40%, #4a3a55 100%)',
        position: 'relative', overflow: 'hidden',
      }}>
        {/* fake editor stripes for visual */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'repeating-linear-gradient(180deg, transparent 0 18px, rgba(255,255,255,0.04) 18px 19px)',
        }} />
        <div style={{
          position: 'absolute', left: 16, top: 18, right: 16,
          fontFamily: 'var(--font-mono)', fontSize: 11, color: 'rgba(255,255,255,0.55)',
          lineHeight: 1.6,
        }}>
          <div><span style={{ color: '#9aa6c9', marginRight: 8 }}>23</span>Widget build(BuildContext c) {`{`}</div>
          <div><span style={{ color: '#9aa6c9', marginRight: 8 }}>24</span>&nbsp;&nbsp;return Scaffold(</div>
          <div><span style={{ color: '#9aa6c9', marginRight: 8 }}>25</span>&nbsp;&nbsp;&nbsp;&nbsp;floatingActionButton: FloatingActionButton.</div>
          <div><span style={{ color: '#9aa6c9', marginRight: 8 }}>26</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style={{ color: '#f3b88a' }}>extended</span>(</div>
        </div>
        {/* play button */}
        <div style={{
          position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%,-50%)',
          width: 56, height: 56, borderRadius: '50%',
          background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(6px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'white',
        }}>
          <IPlay size={22} />
        </div>
        {/* duration */}
        <div style={{
          position: 'absolute', right: 8, bottom: 8,
          background: 'rgba(0,0,0,0.7)', color: 'white',
          fontSize: 11, fontWeight: 500,
          padding: '2px 6px', borderRadius: 4,
        }}>18:42</div>
        {/* progress bar at bottom */}
        <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, height: 3, background: 'rgba(255,255,255,0.2)' }}>
          <div style={{ height: '100%', width: '38%', background: '#FF0033' }} />
        </div>
      </div>

      {/* Video meta */}
      <div style={{ padding: '12px 14px 0' }}>
        <div style={{ fontSize: 16, fontWeight: 600, lineHeight: 1.3, letterSpacing: '-0.01em' }}>
          {SAMPLE_VIDEO.title}
        </div>
        <div style={{ marginTop: 4, fontSize: 12, color: 'var(--muted)' }}>
          {SAMPLE_VIDEO.views} vues · {SAMPLE_VIDEO.age}
        </div>

        {/* action chips */}
        <div style={{ display: 'flex', gap: 8, marginTop: 12, overflow: 'hidden' }}>
          {['👍 4,2 k', '👎', 'Partager', 'Enregistrer', 'Clip'].map((c, i) => (
            <div key={i} style={{
              padding: '6px 12px', borderRadius: 999,
              background: 'var(--surface-2)', fontSize: 12, fontWeight: 500,
              whiteSpace: 'nowrap',
            }}>{c}</div>
          ))}
        </div>

        {/* channel row */}
        <div style={{
          marginTop: 14, display: 'flex', alignItems: 'center', gap: 10,
          paddingBottom: 14,
          borderBottom: '0.5px solid var(--border)',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'linear-gradient(135deg,#7A5AE0,#FF7A8A)',
            color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 600, fontSize: 14,
          }}>MP</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{SAMPLE_VIDEO.channel}</div>
            <div style={{ fontSize: 11, color: 'var(--muted)' }}>184 k abonnés</div>
          </div>
          <div style={{
            padding: '7px 14px', borderRadius: 999,
            background: 'var(--text)', color: 'var(--bg)',
            fontSize: 12, fontWeight: 600,
          }}>S'abonner</div>
        </div>
      </div>

      {/* playlist strip */}
      <div style={{
        margin: '14px 14px 0', padding: 12,
        background: 'var(--surface-2)', borderRadius: 12,
        border: '0.5px solid var(--border)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 11, color: 'var(--muted)' }}>Playlist · Marc Pajak</div>
            <div style={{
              fontSize: 13, fontWeight: 600, marginTop: 2,
              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            }}>{SAMPLE_VIDEO.playlistTitle}</div>
            <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>
              {SAMPLE_VIDEO.playlistIndex} / {SAMPLE_VIDEO.playlistCount}
            </div>
          </div>
          <IChevronD size={20} stroke={1.6} style={{ color: 'var(--muted)' }} />
        </div>
      </div>

      {/* Up next */}
      <div style={{ padding: '18px 14px 0' }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--muted)', marginBottom: 10 }}>
          À SUIVRE
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {UP_NEXT.map((v, i) => (
            <div key={i} style={{ display: 'flex', gap: 10 }}>
              <div style={{
                width: 110, height: 62, borderRadius: 8,
                background: `linear-gradient(135deg, ${v.color}, color-mix(in oklab, ${v.color} 60%, #2a2a2a))`,
                position: 'relative', flexShrink: 0,
              }}>
                <div style={{
                  position: 'absolute', right: 4, bottom: 4,
                  background: 'rgba(0,0,0,0.75)', color: 'white',
                  fontSize: 10, padding: '1px 4px', borderRadius: 3,
                }}>{v.dur}</div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: 13, fontWeight: 600, lineHeight: 1.3,
                  display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical',
                  overflow: 'hidden',
                }}>{v.t}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>
                  {v.ch} · 26 k vues
                </div>
              </div>
              <IDots size={16} style={{ color: 'var(--muted)', flexShrink: 0, marginTop: 2 }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function YouTubeLogo() {
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 1 }}>
      <div style={{
        background: '#FF0033', borderRadius: 5,
        padding: '3px 7px',
        display: 'inline-flex', alignItems: 'center',
      }}>
        <svg width="14" height="10" viewBox="0 0 14 10"><path d="M0 1.5L0 8.5L7 5L0 1.5Z" fill="white" transform="translate(4,0)"/></svg>
      </div>
      <span style={{ fontWeight: 700, fontSize: 16, letterSpacing: '-0.02em' }}>YouTube</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Download FAB (3 styles)
// ─────────────────────────────────────────────────────────────────────────────
function DownloadFAB({ style = 'extended', t, onClick, hint }) {
  const base = {
    position: 'absolute',
    right: 16, bottom: 16,
    zIndex: 5,
    background: 'var(--accent)',
    color: 'white',
    boxShadow: '0 10px 24px -8px color-mix(in oklab, var(--accent) 60%, transparent), 0 2px 6px rgba(0,0,0,0.15)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer', userSelect: 'none',
    transition: 'transform .12s, box-shadow .12s',
  };

  if (style === 'circle') {
    return (
      <div onClick={onClick} style={{ ...base, width: 56, height: 56, borderRadius: '50%' }}>
        <IDownload size={24} stroke={2} />
      </div>
    );
  }

  if (style === 'pill') {
    return (
      <div onClick={onClick} style={{
        ...base,
        left: 16, right: 16, bottom: 16,
        height: 52, borderRadius: 16,
        gap: 10, padding: '0 18px',
        background: 'color-mix(in oklab, var(--accent) 92%, transparent)',
        backdropFilter: 'blur(20px)',
      }}>
        <IDownload size={20} stroke={2} />
        <span style={{ fontSize: 15, fontWeight: 600, flex: 1, textAlign: 'left' }}>{t.download}</span>
        {hint && <span style={{ fontSize: 11, opacity: 0.85 }}>{hint}</span>}
      </div>
    );
  }

  // extended (default)
  return (
    <div onClick={onClick} style={{
      ...base, height: 52, borderRadius: 28,
      gap: 8, padding: '0 18px 0 16px',
    }}>
      <IDownload size={20} stroke={2} />
      <span style={{ fontSize: 15, fontWeight: 600 }}>{t.download}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist radio dialog
// ─────────────────────────────────────────────────────────────────────────────
function PlaylistDialog({ t, choice, setChoice, onCancel, onConfirm, video }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 10,
      background: 'var(--scrim)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 16, animation: 'scrim-in .15s ease',
    }} onClick={onCancel}>
      <div onClick={(e)=>e.stopPropagation()} style={{
        width: '100%', maxWidth: 340,
        background: 'var(--surface)',
        borderRadius: 24, padding: 24,
        animation: 'dialog-in .18s ease',
      }}>
        <div style={{ fontSize: 19, fontWeight: 600, letterSpacing: '-0.01em', lineHeight: 1.25 }}>
          {t.plTitle}
        </div>
        <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 6 }}>
          {t.plSub}
        </div>

        {/* playlist context */}
        <div style={{
          marginTop: 16, padding: 12,
          background: 'var(--surface-2)', borderRadius: 12,
          fontSize: 12, color: 'var(--text-2)',
          display: 'flex', gap: 10, alignItems: 'center',
        }}>
          <IList size={16} stroke={1.8} style={{ color: 'var(--muted)' }} />
          <span style={{
            flex: 1, minWidth: 0,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>{video.playlistTitle}</span>
          <span className="t-mono" style={{ color: 'var(--muted)', fontSize: 11 }}>
            {video.playlistCount}
          </span>
        </div>

        <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 4 }}>
          <RadioRow
            checked={choice === 'one'}
            onClick={() => setChoice('one')}
            title={t.plOne}
            sub={video.title}
          />
          <RadioRow
            checked={choice === 'all'}
            onClick={() => setChoice('all')}
            title={t.plAll(video.playlistCount)}
            sub={`~ ${Math.round(video.playlistCount * 14)} min de contenu`}
          />
        </div>

        <div style={{
          marginTop: 18, display: 'flex', justifyContent: 'flex-end', gap: 4,
        }}>
          <button className="btn btn-ghost" onClick={onCancel} style={{ color: 'var(--text-2)' }}>{t.cancel}</button>
          <button className="btn btn-primary" onClick={onConfirm}>{t.continue}</button>
        </div>
      </div>
    </div>
  );
}

function RadioRow({ checked, onClick, title, sub }) {
  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '12px 8px', margin: '0 -8px',
      borderRadius: 12, cursor: 'pointer',
      background: checked ? 'color-mix(in oklab, var(--accent) 8%, transparent)' : 'transparent',
      transition: 'background .12s',
    }}>
      <span className="radio" data-on={checked ? '1' : '0'} style={{ marginTop: 2 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{title}</div>
        <div style={{
          fontSize: 12, color: 'var(--muted)', marginTop: 2,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{sub}</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Format bottom sheet — linear list
// ─────────────────────────────────────────────────────────────────────────────
const FORMAT_OPTIONS = [
  { k: 'mp4-1080', kind: 'video', label: 'MP4 1080p',  size: '142 Mo', tag: 'Full HD' },
  { k: 'mp4-720',  kind: 'video', label: 'MP4 720p',   size: '78 Mo',  tag: 'HD' },
  { k: 'mp4-360',  kind: 'video', label: 'MP4 360p',   size: '31 Mo',  tag: '' },
  { k: 'mp3-320',  kind: 'audio', label: 'MP3 320 kbps', size: '44 Mo', tag: 'Haute qualité' },
  { k: 'mp3-192',  kind: 'audio', label: 'MP3 192 kbps', size: '27 Mo', tag: '' },
  { k: 'mp3-128',  kind: 'audio', label: 'MP3 128 kbps', size: '18 Mo', tag: 'Léger' },
];

function FormatSheet({ t, lastChoice, onCancel, onPick }) {
  return (
    <PhoneScrim onClose={onCancel}>
      <BottomSheet title={t.fmtTitle}>
        <div style={{ padding: '4px 8px 0' }}>
          {FORMAT_OPTIONS.map((f) => {
            const Ic = f.kind === 'video' ? IFilm : IMusic;
            const isLast = f.k === lastChoice;
            return (
              <div
                key={f.k}
                onClick={() => onPick(f)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  padding: '14px 16px',
                  borderRadius: 14,
                  cursor: 'pointer',
                  background: isLast ? 'color-mix(in oklab, var(--accent) 8%, transparent)' : 'transparent',
                }}
              >
                <div style={{
                  width: 40, height: 40, borderRadius: 12,
                  background: f.kind === 'video' ? 'var(--surface-2)' : 'var(--surface-2)',
                  color: f.kind === 'video' ? 'var(--text)' : 'var(--accent)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <Ic size={20} stroke={1.7} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 15, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span>{f.label}</span>
                    {isLast && (
                      <span style={{
                        fontSize: 10, fontWeight: 600,
                        padding: '2px 7px', borderRadius: 999,
                        background: 'var(--accent)', color: 'white',
                        textTransform: 'uppercase', letterSpacing: '0.04em',
                      }}>{t.fmtRecent}</span>
                    )}
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2, display: 'flex', gap: 8 }}>
                    <span>~ {f.size}</span>
                    {f.tag && <span>· {f.tag}</span>}
                  </div>
                </div>
                <IChevron size={18} stroke={1.6} style={{ color: 'var(--faint)' }} />
              </div>
            );
          })}
        </div>
        <div style={{
          marginTop: 6, padding: '12px 24px 4px',
          fontSize: 11, color: 'var(--muted)', textAlign: 'center',
        }}>
          {t.fmtAsk}
        </div>
      </BottomSheet>
    </PhoneScrim>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// In-progress chip (shown after starting a download)
// ─────────────────────────────────────────────────────────────────────────────
function StartedChip({ t, count = 1 }) {
  return (
    <div style={{
      position: 'absolute',
      left: 16, right: 16, bottom: 16,
      background: 'var(--text)', color: 'var(--bg)',
      borderRadius: 16,
      padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 12,
      zIndex: 6,
      boxShadow: 'var(--shadow-lg)',
      animation: 'sheet-in .22s cubic-bezier(.2,.7,.3,1)',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: '50%',
        background: 'var(--accent)', color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <IDownload size={16} stroke={2.2} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600 }}>
          {count === 1 ? t.downloading : `${count} ${t.downloading.toLowerCase()}`}
        </div>
        <div style={{ fontSize: 11, opacity: 0.65, marginTop: 1 }}>
          Voir dans Mes téléchargements
        </div>
      </div>
      <IChevron size={18} stroke={1.6} style={{ opacity: 0.6 }} />
    </div>
  );
}

Object.assign(window, {
  SAMPLE_VIDEO, UP_NEXT, PLAYLIST_VIDEOS, FORMAT_OPTIONS,
  YouTubeMock, YouTubeLogo, DownloadFAB,
  PlaylistDialog, FormatSheet, StartedChip, RadioRow,
});
