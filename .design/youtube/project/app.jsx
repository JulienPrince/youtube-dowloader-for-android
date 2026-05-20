// app.jsx — assembles the design canvas, all screens, and the Tweaks panel.

const { useState, useEffect, useMemo } = React;

const ACCENT_OPTIONS = [
  '#FF7A00', // primary, picked by user
  '#FF0033', // YouTube red
  '#7C5CFF', // violet
  '#3DDC84', // Android green
  '#FFFFFF', // mono (interpreted as inverted: uses text color, see below)
];

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "accent": "#FF7A00",
  "fab": "extended",
  "density": "cozy",
  "lang": "fr"
}/*EDITMODE-END*/;

// ─────────────────────────────────────────────────────────────────────────────
// Main flow on the home artboard — driven by an internal state machine.
// 'idle' → 'playlist' → 'format' → 'started' (auto-dismiss back to idle)
// ─────────────────────────────────────────────────────────────────────────────
function MainArtboardContent({ t, theme, lang, accent, density, fabStyle }) {
  const [step, setStep] = useState('idle');
  const [plChoice, setPlChoice] = useState('one');
  const [lastFmt, setLastFmt] = useState('mp3-320');
  const [pendingCount, setPendingCount] = useState(1);

  const handleFAB = () => {
    if (SAMPLE_VIDEO.inPlaylist) setStep('playlist');
    else setStep('format');
  };

  const handlePlConfirm = () => {
    setPendingCount(plChoice === 'one' ? 1 : SAMPLE_VIDEO.playlistCount);
    setStep('format');
  };

  const handleFmt = (f) => {
    setLastFmt(f.k);
    setStep('started');
    setTimeout(() => setStep('idle'), 2400);
  };

  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="01 Main · WebView">
      <YouTubeMock t={t} theme={theme} />

      {/* FAB overlay (hidden during sheets / dialogs so it doesn't fight scrim) */}
      {step === 'idle' && (
        <DownloadFAB style={fabStyle} t={t} onClick={handleFAB} hint={SAMPLE_VIDEO.inPlaylist ? `${SAMPLE_VIDEO.playlistCount} en playlist` : null} />
      )}

      {/* started chip */}
      {step === 'started' && <StartedChip t={t} count={pendingCount} />}

      {/* playlist dialog */}
      {step === 'playlist' && (
        <PlaylistDialog
          t={t}
          choice={plChoice}
          setChoice={setPlChoice}
          onCancel={() => setStep('idle')}
          onConfirm={handlePlConfirm}
          video={SAMPLE_VIDEO}
        />
      )}

      {/* format sheet */}
      {step === 'format' && (
        <FormatSheet
          t={t}
          lastChoice={lastFmt}
          onCancel={() => setStep('idle')}
          onPick={handleFmt}
        />
      )}
    </Phone>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Static showcase artboards — playlist dialog and format sheet on their own
// frames so the user can review them in isolation (without having to click
// through the live flow).
// ─────────────────────────────────────────────────────────────────────────────
function PlaylistArtboardContent({ t, theme, lang, accent, density, fabStyle }) {
  const [choice, setChoice] = useState('all');
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="02 Playlist · Dialog">
      <YouTubeMock t={t} theme={theme} />
      <PlaylistDialog
        t={t}
        choice={choice}
        setChoice={setChoice}
        onCancel={() => {}}
        onConfirm={() => {}}
        video={SAMPLE_VIDEO}
      />
    </Phone>
  );
}

function FormatArtboardContent({ t, theme, lang, accent, density, fabStyle }) {
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="03 Format · Bottom sheet">
      <YouTubeMock t={t} theme={theme} />
      <FormatSheet t={t} lastChoice="mp3-320" onCancel={() => {}} onPick={() => {}} />
    </Phone>
  );
}

function NotificationArtboardContent({ t, theme, lang, accent, density }) {
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="04 Notification · Foreground Service" statusTime="9:31">
      <NotificationShade t={t} theme={theme} />
    </Phone>
  );
}

function DownloadsArtboardContent({ t, theme, lang, accent, density, tab }) {
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label={`05 Downloads · ${tab}`}>
      <DownloadsScreen t={t} density={density} initialTab={tab} />
    </Phone>
  );
}

function SettingsArtboardContent({ t, theme, lang, accent, density }) {
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="06 Settings">
      <SettingsScreen t={t} lang={lang} />
    </Phone>
  );
}

function OnboardingArtboardContent({ t, theme, lang, accent, density }) {
  return (
    <Phone theme={theme} density={density} accent={accent} lang={lang} label="00 Onboarding · Permissions">
      <OnboardingScreen t={t} theme={theme} />
    </Phone>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────
function App() {
  const [tw, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const t = STRINGS[tw.lang] || STRINGS.fr;

  // Apply a body bg that reads slightly differently depending on theme so the
  // canvas chrome feels coherent — but the canvas itself owns its bg.
  useEffect(() => {
    document.body.dataset.theme = tw.theme;
  }, [tw.theme]);

  const common = {
    t,
    theme: tw.theme,
    lang: tw.lang,
    accent: tw.accent,
    density: tw.density,
    fabStyle: tw.fab,
  };

  return (
    <>
      <DesignCanvas>
        <DCSection id="flow" title="Flux principal" subtitle="WebView YouTube → FAB → playlist? → format → en cours">
          <DCArtboard id="main"     label="Principal · WebView + FAB (cliquable)" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><MainArtboardContent {...common} /></div>
          </DCArtboard>
          <DCArtboard id="playlist" label="Playlist détectée · radio" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><PlaylistArtboardContent {...common} /></div>
          </DCArtboard>
          <DCArtboard id="format"   label="Choix de format · bottom sheet" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><FormatArtboardContent {...common} /></div>
          </DCArtboard>
          <DCArtboard id="notif"    label="Notification · Foreground Service" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><NotificationArtboardContent {...common} /></div>
          </DCArtboard>
        </DCSection>

        <DCSection id="library" title="Bibliothèque" subtitle="Mes téléchargements — 3 onglets, état persistant via DownloadRepository">
          <DCArtboard id="dl-active" label="En cours" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><DownloadsArtboardContent {...common} tab="active" /></div>
          </DCArtboard>
          <DCArtboard id="dl-done"   label="Terminés" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><DownloadsArtboardContent {...common} tab="done" /></div>
          </DCArtboard>
          <DCArtboard id="dl-err"    label="Erreurs (playlist, skip + log)" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><DownloadsArtboardContent {...common} tab="error" /></div>
          </DCArtboard>
        </DCSection>

        <DCSection id="setup" title="Setup & paramètres" subtitle="Premier lancement et réglages — incluant le moteur d'extraction câblé sur l'interface VideoExtractor.">
          <DCArtboard id="onboarding" label="Onboarding · permissions" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><OnboardingArtboardContent {...common} /></div>
          </DCArtboard>
          <DCArtboard id="settings"   label="Paramètres" width={PHONE_W + 16} height={PHONE_H + 16}>
            <div style={{ padding: 8 }}><SettingsArtboardContent {...common} /></div>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel>
        <TweakSection label="Apparence" />
        <TweakRadio
          label="Thème"
          value={tw.theme}
          options={[
            { value: 'light', label: 'Clair' },
            { value: 'dark',  label: 'Sombre' },
          ]}
          onChange={(v) => setTweak('theme', v)}
        />
        <TweakColor
          label="Couleur d'accent"
          value={tw.accent}
          options={ACCENT_OPTIONS}
          onChange={(v) => setTweak('accent', v)}
        />

        <TweakSection label="Layout" />
        <TweakRadio
          label="Style du FAB"
          value={tw.fab}
          options={[
            { value: 'extended', label: 'Extended' },
            { value: 'circle',   label: 'Circulaire' },
            { value: 'pill',     label: 'Pill' },
          ]}
          onChange={(v) => setTweak('fab', v)}
        />
        <TweakRadio
          label="Densité (téléchargements)"
          value={tw.density}
          options={[
            { value: 'cozy',    label: 'Confortable' },
            { value: 'compact', label: 'Compact' },
          ]}
          onChange={(v) => setTweak('density', v)}
        />

        <TweakSection label="Langue" />
        <TweakRadio
          label="Locale"
          value={tw.lang}
          options={[
            { value: 'fr', label: 'FR' },
            { value: 'en', label: 'EN' },
          ]}
          onChange={(v) => setTweak('lang', v)}
        />
      </TweaksPanel>
    </>
  );
}

// Boot ────────────────────────────────────────────────────────────────────────
ReactDOM.createRoot(document.getElementById('root')).render(<App />);
