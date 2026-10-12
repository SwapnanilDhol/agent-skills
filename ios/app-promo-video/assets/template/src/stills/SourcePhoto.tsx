import { AbsoluteFill, Img, staticFile } from "remotion";

// A printed ticket lying on a desk: what the mocked camera scene "sees".
// Make it match the result the scan reveals (same name, date, colours) so the
// story reads. Rendered to public/source-photo.jpg with `npm run source-photo`.
// For receipts, cards, labels etc., keep the desk and swap the printed object.

const TICKET = {
  kicker: "HARBORSIDE LIVE PRESENTS",
  title: "HARBORSIDE SUMMER FEST",
  subtitle: "One day · Three stages",
  fields: [
    { label: "DATE", value: "SUN AUG 17" },
    { label: "GATES", value: "1:30" },
    { label: "AREA", value: "GA" },
  ],
  footer: "ADMIT ONE · Harborside Grounds, Boston",
  number: "HS-81726",
  price: "$68.00",
  gradient:
    "radial-gradient(ellipse at 25% 20%, #FFB15C 0%, transparent 55%), radial-gradient(ellipse at 80% 85%, #C2185B 0%, transparent 60%), linear-gradient(130deg, #FF7A3D 0%, #F0443A 50%, #B3123F 100%)",
};

const Field = ({ label, value }: { label: string; value: string }) => (
  <div>
    <div style={{ fontSize: 20, letterSpacing: 3, fontWeight: 700, opacity: 0.6 }}>{label}</div>
    <div style={{ fontSize: 40, fontWeight: 800, marginTop: 4 }}>{value}</div>
  </div>
);

export const SourcePhoto = () => (
  <AbsoluteFill
    style={{
      // Warm oak desk with grain, lit from the top left.
      background: [
        "radial-gradient(ellipse at 20% 10%, rgba(255,240,215,0.55), transparent 60%)",
        "repeating-linear-gradient(92deg, rgba(90,50,20,0.10) 0 3px, transparent 3px 19px)",
        "repeating-linear-gradient(88deg, rgba(60,30,10,0.07) 0 1px, transparent 1px 7px)",
        "linear-gradient(180deg, #B9875A, #8E5E36)",
      ].join(","),
      alignItems: "center",
      justifyContent: "center",
      fontFamily: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    }}
  >
    <div
      style={{
        display: "flex",
        width: 1040,
        height: 470,
        transform: "rotate(-5deg) scale(1.3)",
        boxShadow: "18px 30px 40px rgba(40, 20, 5, 0.45), 2px 3px 6px rgba(40,20,5,0.3)",
        borderRadius: 14,
        overflow: "hidden",
        color: "#14101C",
      }}
    >
      <div
        style={{
          flex: 1,
          padding: "44px 48px",
          background: TICKET.gradient,
          color: "white",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
        }}
      >
        <div>
          <div style={{ fontSize: 22, letterSpacing: 6, fontWeight: 700, opacity: 0.85 }}>{TICKET.kicker}</div>
          <div style={{ fontSize: 76, fontWeight: 900, letterSpacing: -2, lineHeight: 0.95, marginTop: 18 }}>
            {TICKET.title}
          </div>
          <div style={{ fontSize: 40, fontWeight: 600, marginTop: 6 }}>{TICKET.subtitle}</div>
        </div>
        <div style={{ display: "flex", gap: 52 }}>
          {TICKET.fields.map((field) => (
            <Field key={field.label} {...field} />
          ))}
        </div>
        <div style={{ fontSize: 26, fontWeight: 600, opacity: 0.9 }}>{TICKET.footer}</div>
      </div>
      <div
        style={{
          width: 250,
          background: "#F6F1E7",
          borderLeft: "4px dashed rgba(20,16,28,0.35)",
          padding: "40px 28px",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div style={{ textAlign: "center" }}>
          <div style={{ fontSize: 18, letterSpacing: 3, fontWeight: 700, opacity: 0.55 }}>TICKET</div>
          <div style={{ fontSize: 34, fontWeight: 800 }}>{TICKET.number}</div>
        </div>
        <Img src={staticFile("source-qr.png")} style={{ width: 190, height: 190, imageRendering: "pixelated" }} />
        <div style={{ fontSize: 30, fontWeight: 800 }}>{TICKET.price}</div>
      </div>
    </div>
    {/* Soft vignette so it reads as a phone photo, not a render. */}
    <AbsoluteFill style={{ background: "radial-gradient(ellipse at center, transparent 55%, rgba(30,15,5,0.45))" }} />
  </AbsoluteFill>
);
