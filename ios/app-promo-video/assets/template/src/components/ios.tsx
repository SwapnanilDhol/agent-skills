import { CSSProperties, ReactNode } from "react";

// iPhone 17 Pro screen in points. Mocked screens are laid out in points and
// scaled to the recording's pixel size so they sit 1:1 with real captures.
export const SCREEN_POINTS = { width: 402, height: 874 };
export const IOS_FONT = '"SF Pro Text", "SF Pro Display", -apple-system, system-ui, sans-serif';
export const SYSTEM_BLUE = "#0A84FF";

export const PointsScreen = ({ width, children }: { width: number; children: ReactNode }) => (
  <div
    style={{
      width: SCREEN_POINTS.width,
      height: SCREEN_POINTS.height,
      transform: `scale(${width / SCREEN_POINTS.width})`,
      transformOrigin: "top left",
      position: "relative",
      overflow: "hidden",
      fontFamily: IOS_FONT,
    }}
  >
    {children}
  </div>
);

export const StatusBar = ({ dark = false }: { dark?: boolean }) => {
  const ink = dark ? "white" : "black";
  const bar = (h: number): CSSProperties => ({ width: 3, height: h, borderRadius: 1, background: ink });
  return (
    <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 54, zIndex: 10 }}>
      <div style={{ position: "absolute", left: 50, top: 17, fontSize: 17, fontWeight: 600, color: ink }}>9:41</div>
      <div
        style={{ position: "absolute", left: 138, top: 11, width: 126, height: 37, borderRadius: 20, background: "black" }}
      />
      <div style={{ position: "absolute", right: 34, top: 21, display: "flex", alignItems: "flex-end", gap: 6 }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 1.5 }}>
          <div style={bar(4)} />
          <div style={bar(6)} />
          <div style={bar(8)} />
          <div style={bar(10)} />
        </div>
        <svg width="15" height="11" viewBox="0 0 15 11">
          <path d="M7.5 11 L4.6 7.9 A4.2 4.2 0 0 1 10.4 7.9 Z" fill={ink} />
          <path d="M2.3 5.6 A7.4 7.4 0 0 1 12.7 5.6 L11.4 6.9 A5.6 5.6 0 0 0 3.6 6.9 Z" fill={ink} />
          <path d="M0 3.3 A10.6 10.6 0 0 1 15 3.3 L13.7 4.6 A8.8 8.8 0 0 0 1.3 4.6 Z" fill={ink} />
        </svg>
        <div
          style={{
            width: 25,
            height: 12,
            borderRadius: 4,
            border: `1.2px solid ${dark ? "rgba(255,255,255,0.5)" : "rgba(0,0,0,0.4)"}`,
            padding: 1.5,
          }}
        >
          <div style={{ width: "100%", height: "100%", borderRadius: 2, background: ink }} />
        </div>
      </div>
    </div>
  );
};

export const PrimaryButton = ({ label, style }: { label: ReactNode; style?: CSSProperties }) => (
  <div
    style={{
      position: "absolute",
      left: 20,
      right: 20,
      bottom: 46,
      height: 54,
      borderRadius: 27,
      background: SYSTEM_BLUE,
      color: "white",
      fontSize: 17,
      fontWeight: 600,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      ...style,
    }}
  >
    {label}
  </div>
);
