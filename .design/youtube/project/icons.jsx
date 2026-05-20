// icons.jsx — small set of minimal stroke icons (1.5px), inherits currentColor.

function Icon({ children, size = 20, stroke = 1.6, ...rest }) {
  return (
    <svg
      width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth={stroke}
      strokeLinecap="round" strokeLinejoin="round"
      {...rest}
    >{children}</svg>
  );
}

const IDownload = (p) => <Icon {...p}><path d="M12 4v12"/><path d="M6 11l6 6 6-6"/><path d="M5 20h14"/></Icon>;
const IChevron  = (p) => <Icon {...p}><path d="M9 6l6 6-6 6"/></Icon>;
const IChevronL = (p) => <Icon {...p}><path d="M15 6l-6 6 6 6"/></Icon>;
const IChevronD = (p) => <Icon {...p}><path d="M6 9l6 6 6-6"/></Icon>;
const ICheck    = (p) => <Icon {...p}><path d="M5 12l5 5L20 7"/></Icon>;
const IClose    = (p) => <Icon {...p}><path d="M6 6l12 12M18 6L6 18"/></Icon>;
const IPause    = (p) => <Icon {...p}><path d="M9 5v14M15 5v14"/></Icon>;
const IPlay     = (p) => <Icon {...p}><path d="M7 5l12 7-12 7V5z" fill="currentColor"/></Icon>;
const IPlayO    = (p) => <Icon {...p}><path d="M8 5l11 7-11 7V5z"/></Icon>;
const IList     = (p) => <Icon {...p}><path d="M8 6h12M8 12h12M8 18h12"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/></Icon>;
const ISettings = (p) => <Icon {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.6a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9c.36.69.93 1 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></Icon>;
const IMusic    = (p) => <Icon {...p}><path d="M9 18V6l10-2v12"/><circle cx="6" cy="18" r="3"/><circle cx="16" cy="16" r="3"/></Icon>;
const IFilm     = (p) => <Icon {...p}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M3 14h18M8 5v14M16 5v14"/></Icon>;
const IRefresh  = (p) => <Icon {...p}><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M3 21v-5h5"/></Icon>;
const IError    = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5v.5"/></Icon>;
const IFolder   = (p) => <Icon {...p}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/></Icon>;
const IInfo     = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 10v6M12 7.5v.5"/></Icon>;
const ISearch   = (p) => <Icon {...p}><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.5-4.5"/></Icon>;
const IBack     = (p) => <Icon {...p}><path d="M19 12H5M12 19l-7-7 7-7"/></Icon>;
const IHome     = (p) => <Icon {...p}><path d="M3 11l9-7 9 7v9a2 2 0 0 1-2 2h-3v-7H8v7H5a2 2 0 0 1-2-2v-9z"/></Icon>;
const IShorts   = (p) => <Icon {...p}><path d="M14 4l5 3-9 13-5-3 9-13z"/><path d="M10 11l4 2"/></Icon>;
const IBell     = (p) => <Icon {...p}><path d="M18 16v-5a6 6 0 1 0-12 0v5l-2 2v1h16v-1l-2-2z"/><path d="M10 21h4"/></Icon>;
const IDots     = (p) => <Icon {...p}><circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/></Icon>;
const IUser     = (p) => <Icon {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></Icon>;
const IFolder2  = (p) => <Icon {...p}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/></Icon>;
const IFlash    = (p) => <Icon {...p}><path d="M13 3L4 14h6l-1 7 9-11h-6l1-7z"/></Icon>;
const IGlobe    = (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></Icon>;
const IShield   = (p) => <Icon {...p}><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z"/></Icon>;
const ILibrary  = (p) => <Icon {...p}><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></Icon>;
const IPlus     = (p) => <Icon {...p}><path d="M12 5v14M5 12h14"/></Icon>;

Object.assign(window, {
  Icon,
  IDownload, IChevron, IChevronL, IChevronD, ICheck, IClose, IPause, IPlay, IPlayO,
  IList, ISettings, IMusic, IFilm, IRefresh, IError, IFolder, IInfo, ISearch,
  IBack, IHome, IShorts, IBell, IDots, IUser, IFolder2, IFlash, IGlobe, IShield,
  ILibrary, IPlus,
});
