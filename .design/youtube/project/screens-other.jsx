// screens-other.jsx — Onboarding, Downloads (3 tabs), Settings, Notification shade.

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding / permissions
// ─────────────────────────────────────────────────────────────────────────────
function OnboardingScreen({ t, theme }) {
  const perms = [
    { k: 'storage', icon: IFolder2, title: t.obP1, sub: t.obP1s },
    { k: 'notif',   icon: IBell,    title: t.obP2, sub: t.obP2s },
    { k: 'bg',      icon: IFlash,   title: t.obP3, sub: t.obP3s },
  ];
  // mock state: first two granted, third pending — purely visual
  const status = { storage: 'on', notif: 'on', bg: 'pending' };

  return (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      padding: '12px 28px 24px',
    }}>
      {/* tiny header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.appName}</span>
        <span style={{ fontSize: 11, color: 'var(--muted)' }}>1 / 1</span>
      </div>

      {/* big mark */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <BrandMark />
        <div style={{
          marginTop: 28, fontSize: 28, fontWeight: 600,
          letterSpacing: '-0.02em', lineHeight: 1.15, textWrap: 'balance',
        }}>{t.obTitle}</div>
        <div style={{
          marginTop: 12, fontSize: 14, color: 'var(--muted)',
          lineHeight: 1.45, textWrap: 'pretty',
        }}>{t.obSub}</div>

        {/* perms list */}
        <div style={{ marginTop: 28, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {perms.map((p) => {
            const Ic = p.icon;
            const granted = status[p.k] === 'on';
            return (
              <div key={p.k} style={{
                display: 'flex', alignItems: 'center', gap: 14,
                padding: '14px 0',
                borderBottom: '0.5px solid var(--border)',
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: 'var(--surface-2)',
                  color: granted ? 'var(--accent)' : 'var(--text-2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <Ic size={18} stroke={1.7} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{p.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 1 }}>{p.sub}</div>
                </div>
                <div style={{
                  fontSize: 12, fontWeight: 600,
                  color: granted ? 'var(--muted)' : 'var(--text)',
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                }}>
                  {granted ? <><ICheck size={14} stroke={2.2} />{t.obAllowed}</> : t.obAllow}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* CTA */}
      <button className="btn btn-primary" style={{ width: '100%', height: 52, fontSize: 15 }}>
        {t.obStart}
      </button>
    </div>
  );
}

function BrandMark() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{
        width: 56, height: 56, borderRadius: 16,
        background: 'var(--accent)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
        boxShadow: '0 10px 28px -10px color-mix(in oklab, var(--accent) 70%, transparent)',
      }}>
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 4v12"/><path d="M6 11l6 6 6-6"/><path d="M5 20h14"/>
        </svg>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Downloads (3 tabs)
// ─────────────────────────────────────────────────────────────────────────────
const DL_ACTIVE = [
  { id: 'a1', title: "Live coding: building a minimal Flutter UI in 2026", channel: "Marc Pajak", fmt: "MP4 1080p", size: "142 Mo", done: 0.42, eta: "1 min 12 s restant", phase: 'dl', color: '#FFB8B8' },
  { id: 'a2', title: "Material 3 expressive — what changed",               channel: "Flutter",     fmt: "MP3 320 kbps", size: "44 Mo",  done: 0.88, eta: "Conversion MP3…", phase: 'conv', color: '#FFD2B0' },
  { id: 'a3', title: "Riverpod 3 in 14 minutes",                           channel: "Code w/ Andrea", fmt: "MP3 320 kbps", size: "27 Mo", done: 0, eta: "En file", phase: 'queue', color: '#B8D8FF' },
  { id: 'a4', title: "FFmpeg on Android: the missing manual",              channel: "Native Things", fmt: "MP4 720p", size: "78 Mo", done: 0, eta: "En file", phase: 'queue', color: '#FFE08A' },
];
const DL_DONE = [
  { id: 'd1', title: "Brutalist UI in Flutter (in 2026 it's back)", channel: "Marc Pajak", fmt: "MP3 320 kbps", size: "31 Mo", at: "il y a 6 min", color: '#C8F5C0' },
  { id: 'd2', title: "Building offline-first apps with Drift",      channel: "Simon Lightfoot", fmt: "MP4 720p",  size: "112 Mo", at: "il y a 22 min", color: '#D6C8F5' },
  { id: 'd3', title: "Foreground services done right",              channel: "Native Things", fmt: "MP4 1080p", size: "204 Mo", at: "hier, 22:14", color: '#F5D2D8' },
  { id: 'd4', title: "Chill lofi coding mix · 3h",                  channel: "lo-fi café", fmt: "MP3 320 kbps", size: "412 Mo", at: "hier, 16:08", color: '#B0E8F5' },
];
const DL_ERR = [
  { id: 'e1', title: "Private leak: Flutter 4 sneak peek",          channel: "Anonyme",   fmt: "MP4 1080p", size: "—", reason: "Vidéo privée", at: "il y a 12 min", color: '#888' },
  { id: 'e2', title: "Vlog #42 — week recap",                        channel: "Marc Pajak", fmt: "MP4 720p",  size: "—", reason: "Restreinte par âge", at: "il y a 1 h", color: '#888' },
];

function DownloadsScreen({ t, density = 'cozy', initialTab = 'active' }) {
  const [tab, setTab] = React.useState(initialTab);

  const counts = {
    active: DL_ACTIVE.length,
    done:   DL_DONE.length,
    error:  DL_ERR.length,
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* header */}
      <div style={{
        padding: '14px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <IBack size={22} stroke={1.7} style={{ color: 'var(--text)' }} />
          <span style={{ fontSize: 17, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.dlTitle}</span>
        </div>
        <ISearch size={20} stroke={1.7} style={{ color: 'var(--muted)' }} />
      </div>

      {/* tabs */}
      <div style={{
        display: 'flex', gap: 24, padding: '8px 20px 0',
        borderBottom: '0.5px solid var(--border)',
      }}>
        <div className="tab" data-active={tab==='active'?1:0} onClick={()=>setTab('active')}>
          {t.tabActive}
          <Pill n={counts.active} active={tab==='active'} />
        </div>
        <div className="tab" data-active={tab==='done'?1:0}   onClick={()=>setTab('done')}>
          {t.tabDone}
          <Pill n={counts.done} active={tab==='done'} />
        </div>
        <div className="tab" data-active={tab==='error'?1:0}  onClick={()=>setTab('error')}>
          {t.tabError}
          <Pill n={counts.error} active={tab==='error'} accent />
        </div>
      </div>

      {/* list */}
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 0 16px' }}>
        {tab === 'active' && DL_ACTIVE.map((d) => <ActiveRow key={d.id} d={d} t={t} density={density} />)}
        {tab === 'done'   && DL_DONE.map((d)   => <DoneRow   key={d.id} d={d} t={t} density={density} />)}
        {tab === 'error'  && DL_ERR.map((d)    => <ErrorRow  key={d.id} d={d} t={t} density={density} />)}
      </div>
    </div>
  );
}

function Pill({ n, active, accent }) {
  if (n == null || n === 0) return null;
  return (
    <span style={{
      marginLeft: 6,
      fontSize: 11, fontWeight: 600,
      padding: '1px 7px',
      borderRadius: 999,
      background: active
        ? (accent ? 'color-mix(in oklab, var(--accent) 18%, transparent)' : 'var(--surface-2)')
        : 'var(--surface-2)',
      color: active ? (accent ? 'var(--accent)' : 'var(--text)') : 'var(--muted)',
    }}>{n}</span>
  );
}

function Thumb({ color, size = 56, dur, icon }) {
  return (
    <div style={{
      width: size, height: Math.round(size * 0.62), borderRadius: 8,
      background: typeof color === 'string'
        ? `linear-gradient(135deg, ${color}, color-mix(in oklab, ${color} 55%, #2a2a2a))`
        : 'var(--surface-2)',
      flexShrink: 0, position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: 'rgba(255,255,255,0.9)',
    }}>
      {icon}
      {dur && (
        <span style={{
          position: 'absolute', right: 3, bottom: 3,
          background: 'rgba(0,0,0,0.7)', color: 'white',
          fontSize: 9, padding: '0 4px', borderRadius: 3,
        }}>{dur}</span>
      )}
    </div>
  );
}

function ActiveRow({ d, t, density }) {
  const compact = density === 'compact';
  return (
    <div style={{
      padding: compact ? '10px 20px' : '14px 20px',
      borderBottom: '0.5px solid var(--border)',
    }}>
      <div style={{ display: 'flex', gap: 12 }}>
        <Thumb color={d.color} size={compact ? 48 : 56} icon={
          d.fmt.startsWith('MP3') ? <IMusic size={16} /> : <IFilm size={16} />
        } />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: compact ? 13 : 14, fontWeight: 600, lineHeight: 1.3,
            display: '-webkit-box', WebkitLineClamp: compact ? 1 : 2, WebkitBoxOrient: 'vertical',
            overflow: 'hidden',
          }}>{d.title}</div>
          <div style={{
            marginTop: 3, fontSize: 11, color: 'var(--muted)',
            display: 'flex', gap: 6, alignItems: 'center',
          }}>
            <span>{d.fmt}</span><span>·</span><span>{d.size}</span>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 4, marginTop: 2, flexShrink: 0 }}>
          {d.phase !== 'queue' && (
            <button style={iconBtn}><IPause size={16} stroke={1.8} /></button>
          )}
          <button style={iconBtn}><IClose size={16} stroke={1.8} /></button>
        </div>
      </div>

      {/* progress */}
      <div style={{ marginTop: compact ? 6 : 10 }}>
        <div className={`pbar ${d.phase==='queue' ? '' : ''}`}>
          {d.phase === 'conv'
            ? <i style={{
                width: '100%',
                background: 'repeating-linear-gradient(45deg, var(--accent) 0 6px, color-mix(in oklab, var(--accent) 50%, transparent) 6px 12px)',
              }} />
            : <i style={{ width: `${Math.round(d.done * 100)}%` }} />}
        </div>
        <div style={{
          marginTop: 6, display: 'flex', justifyContent: 'space-between',
          fontSize: 11, color: 'var(--muted)',
        }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            {d.phase === 'queue' && <span style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--faint)' }} />}
            {d.phase === 'conv' && <span className="pulse-dot" style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--accent)' }} />}
            {d.phase === 'dl' && <span style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--accent)' }} />}
            {d.eta}
          </span>
          {d.phase === 'dl' && <span className="t-mono">{Math.round(d.done*100)}%</span>}
        </div>
      </div>
    </div>
  );
}

function DoneRow({ d, t, density }) {
  const compact = density === 'compact';
  return (
    <div style={{
      padding: compact ? '8px 20px' : '12px 20px',
      borderBottom: '0.5px solid var(--border)',
      display: 'flex', gap: 12, alignItems: 'center',
    }}>
      <Thumb color={d.color} size={compact ? 44 : 52} icon={
        d.fmt.startsWith('MP3') ? <IMusic size={15} /> : <IFilm size={15} />
      } />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: compact ? 13 : 14, fontWeight: 600, lineHeight: 1.3,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{d.title}</div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>
          {d.fmt} · {d.size} · {d.at}
        </div>
      </div>
      <button style={iconBtn}><IDots size={16} /></button>
    </div>
  );
}

function ErrorRow({ d, t, density }) {
  const compact = density === 'compact';
  return (
    <div style={{
      padding: compact ? '10px 20px' : '14px 20px',
      borderBottom: '0.5px solid var(--border)',
      display: 'flex', gap: 12,
    }}>
      <div style={{
        width: compact ? 44 : 52, height: compact ? 28 : 32, borderRadius: 8,
        background: 'color-mix(in oklab, #E04444 12%, var(--surface-2))',
        color: '#E04444',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <IError size={18} stroke={1.8} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: compact ? 13 : 14, fontWeight: 600, lineHeight: 1.3,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{d.title}</div>
        <div style={{ fontSize: 11, color: '#E04444', marginTop: 2 }}>
          {d.reason}
        </div>
        <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 1 }}>
          {d.fmt} · {d.at}
        </div>
      </div>
      <button style={{ ...iconBtn, color: 'var(--text)' }}>
        <IRefresh size={16} stroke={1.8} />
      </button>
    </div>
  );
}

const iconBtn = {
  width: 32, height: 32, borderRadius: 8,
  background: 'transparent', border: 0,
  color: 'var(--text-2)',
  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer', padding: 0,
};

// ─────────────────────────────────────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────────────────────────────────────
function SettingsScreen({ t, lang }) {
  return (
    <div style={{ flex: 1, overflow: 'auto' }}>
      <div style={{
        padding: '14px 20px', display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <IBack size={22} stroke={1.7} style={{ color: 'var(--text)' }} />
        <span style={{ fontSize: 17, fontWeight: 600, letterSpacing: '-0.01em' }}>{t.setTitle}</span>
      </div>

      {/* extraction engine */}
      <SetSection label={t.secEngine} />
      <SetEngineCard
        active
        title={t.engYE}
        sub={t.engYE_s}
        tag="v1"
      />
      <SetEngineCard
        disabled
        title={t.engYtdlp}
        sub={t.engYtdlp_s}
        tag={t.soon}
      />

      {/* defaults */}
      <SetSection label={t.secDefaults} />
      <SetRow title={t.fmtDefault} value={t.fmtAsk} />
      <SetRow title={t.audioQ} value="320 kbps" />
      <SetRow title={t.videoQ} value="1080p" />

      {/* storage */}
      <SetSection label={t.secStorage} />
      <SetRow title={t.folderMusic}  value="Music/Tubebox"  icon={<IFolder size={18} stroke={1.6} />} />
      <SetRow title={t.folderVideo}  value="Movies/Tubebox" icon={<IFolder size={18} stroke={1.6} />} />

      {/* about */}
      <SetSection label={t.secAbout} />
      <SetRow title={t.version} value="1.0.0" />
      <SetRow title="Build" value="2026.05.20 · APK" />

      <div style={{ height: 32 }} />
    </div>
  );
}

function SetSection({ label }) {
  return (
    <div style={{
      padding: '20px 20px 8px',
      fontSize: 11, fontWeight: 600,
      letterSpacing: '0.08em', textTransform: 'uppercase',
      color: 'var(--muted)',
    }}>{label}</div>
  );
}

function SetRow({ title, value, icon }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 20px',
      borderTop: '0.5px solid var(--border)',
    }}>
      {icon && <span style={{ color: 'var(--muted)' }}>{icon}</span>}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 500 }}>{title}</div>
      </div>
      <div style={{ fontSize: 13, color: 'var(--muted)' }}>{value}</div>
      <IChevron size={16} stroke={1.5} style={{ color: 'var(--faint)' }} />
    </div>
  );
}

function SetEngineCard({ title, sub, tag, active, disabled }) {
  return (
    <div style={{
      margin: '0 16px 8px', padding: '14px 16px',
      borderRadius: 14,
      background: active ? 'color-mix(in oklab, var(--accent) 7%, transparent)' : 'var(--surface-2)',
      border: active ? '0.5px solid color-mix(in oklab, var(--accent) 35%, transparent)' : '0.5px solid var(--border)',
      display: 'flex', gap: 12, alignItems: 'flex-start',
      opacity: disabled ? 0.55 : 1,
    }}>
      <span className="radio" data-on={active ? '1' : '0'} style={{ marginTop: 2 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className="t-mono" style={{ fontSize: 13, fontWeight: 600 }}>{title}</span>
          <span style={{
            fontSize: 10, fontWeight: 600,
            padding: '2px 6px', borderRadius: 999,
            background: active ? 'var(--accent)' : 'var(--border)',
            color: active ? 'white' : 'var(--muted)',
            textTransform: 'uppercase', letterSpacing: '0.04em',
          }}>{tag}</span>
        </div>
        <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4, lineHeight: 1.4 }}>{sub}</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification shade (Foreground Service download in progress)
// ─────────────────────────────────────────────────────────────────────────────
function NotificationShade({ t, theme }) {
  return (
    <div style={{
      flex: 1, position: 'relative',
      background: theme === 'dark'
        ? 'radial-gradient(circle at 30% 0%, #2a1a0d 0%, #0a0a0a 60%)'
        : 'radial-gradient(circle at 30% 0%, #ffe8d4 0%, #f0eee9 60%)',
      overflow: 'hidden',
    }}>
      {/* quick toggles row */}
      <div style={{
        padding: '24px 24px 12px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        color: 'var(--muted)',
        fontSize: 12,
      }}>
        <span>jeu. 20 mai</span>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
          <ISettings size={14} stroke={1.6} />
          <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--text)' }}>9:30</span>
        </span>
      </div>
      <div style={{ padding: '0 16px 14px', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        {['Wi-Fi · Mango', 'Bluetooth', 'NPDD', 'Mode avion'].map((q, i) => (
          <div key={i} style={{
            padding: '8px 14px', borderRadius: 999,
            background: i === 0 ? 'var(--accent)' : 'color-mix(in oklab, var(--text) 8%, transparent)',
            color: i === 0 ? 'white' : 'var(--text)',
            fontSize: 12, fontWeight: 500,
          }}>{q}</div>
        ))}
      </div>

      {/* slider mock */}
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{
          height: 6, borderRadius: 999, background: 'color-mix(in oklab, var(--text) 10%, transparent)',
          position: 'relative',
        }}>
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '60%', background: 'var(--text)', borderRadius: 999 }} />
        </div>
      </div>

      {/* The notification we're showcasing */}
      <DownloadNotification t={t} highlighted />

      {/* a non-highlighted one (existing system notif) for context */}
      <div style={{ padding: '14px 16px 0' }}>
        <SystemNotif
          icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="#1ED760"><circle cx="12" cy="12" r="10"/><path d="M7 10c2-1 6-1 9 1M7 13c2-.5 5-.5 7.5 1M8 16c1.5-.5 4-.5 6 .5" stroke="#000" strokeWidth="1.4" fill="none" strokeLinecap="round"/></svg>}
          app="Spotify" when="3 min" title="Daily Mix 2" body="Mis à jour pour vous." />
      </div>

      <div style={{ position: 'absolute', bottom: 16, left: 16, right: 16, display: 'flex', justifyContent: 'space-between', color: 'var(--muted)', fontSize: 11 }}>
        <span>Tout effacer</span>
        <span>Gérer</span>
      </div>
    </div>
  );
}

function DownloadNotification({ t, highlighted }) {
  const done = 17, total = 30;
  return (
    <div style={{
      margin: '0 16px',
      background: 'var(--surface)',
      borderRadius: 22,
      padding: '14px 16px',
      boxShadow: highlighted ? '0 16px 40px -16px color-mix(in oklab, var(--accent) 80%, transparent), 0 4px 12px rgba(0,0,0,0.12)' : 'none',
      border: highlighted ? '0.5px solid color-mix(in oklab, var(--accent) 35%, transparent)' : '0.5px solid var(--border)',
      position: 'relative',
    }}>
      {highlighted && (
        <div style={{
          position: 'absolute', top: -10, right: 14,
          fontSize: 10, fontWeight: 600,
          padding: '3px 8px', borderRadius: 999,
          background: 'var(--accent)', color: 'white',
          letterSpacing: '0.06em', textTransform: 'uppercase',
        }}>Foreground Service</div>
      )}

      {/* header row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: 'var(--muted)' }}>
        <span style={{
          width: 16, height: 16, borderRadius: 4,
          background: 'var(--accent)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <IDownload size={10} stroke={2.4} style={{ color: 'white' }} />
        </span>
        <span style={{ fontWeight: 600, color: 'var(--text)' }}>{t.notifApp}</span>
        <span>·</span><span>{t.notifNow}</span>
        <span style={{ marginLeft: 'auto', display: 'inline-flex', gap: 4 }}>
          <span className="pulse-dot" style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--accent)' }} />
        </span>
      </div>

      {/* body */}
      <div style={{ marginTop: 10, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        <Thumb color="#FFB8B8" size={48} icon={<IFilm size={14} />} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 600, lineHeight: 1.3 }}>
            {t.notifTitle(done, total)} · « Flutter from scratch »
          </div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>
            Marc Pajak · MP4 720p · 1 min 12 s restant
          </div>
          <div style={{ marginTop: 8 }} className="pbar">
            <i style={{ width: `${Math.round(done/total*100)}%` }} />
          </div>
        </div>
      </div>

      {/* actions */}
      <div style={{
        display: 'flex', gap: 4, marginTop: 12,
        marginLeft: 60, // align with body text
      }}>
        <NotifBtn label={t.notifPause} icon={<IPause size={13} stroke={2} />} />
        <NotifBtn label={t.notifAll} />
      </div>
    </div>
  );
}

function NotifBtn({ label, icon }) {
  return (
    <button style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '7px 12px', borderRadius: 999,
      background: 'var(--surface-2)', color: 'var(--text)',
      fontSize: 12, fontWeight: 600, border: 0,
      cursor: 'pointer',
    }}>
      {icon}{label}
    </button>
  );
}

function SystemNotif({ icon, app, when, title, body }) {
  return (
    <div style={{
      background: 'var(--surface)', borderRadius: 22,
      padding: '14px 16px',
      border: '0.5px solid var(--border)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: 'var(--muted)' }}>
        {icon}
        <span style={{ fontWeight: 600, color: 'var(--text)' }}>{app}</span>
        <span>·</span><span>{when}</span>
      </div>
      <div style={{ marginTop: 6, fontSize: 13, fontWeight: 600 }}>{title}</div>
      <div style={{ fontSize: 12, color: 'var(--muted)' }}>{body}</div>
    </div>
  );
}

Object.assign(window, {
  OnboardingScreen, BrandMark,
  DownloadsScreen, ActiveRow, DoneRow, ErrorRow, Pill, Thumb,
  SettingsScreen, SetSection, SetRow, SetEngineCard,
  NotificationShade, DownloadNotification, SystemNotif, NotifBtn,
  DL_ACTIVE, DL_DONE, DL_ERR,
});
