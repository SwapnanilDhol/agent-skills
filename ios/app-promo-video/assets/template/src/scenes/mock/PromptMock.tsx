import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { PrimaryButton, StatusBar, SYSTEM_BLUE } from "../../components/ios";
import { ResultReveal, ResultRevealProps } from "./ResultReveal";

export type PromptMockProps = {
  title: string;
  subtitle: string;
  prompt: string;
  chips?: string[];
  buttonLabel?: string;
  workingLabel?: string;
  reveal: Omit<ResultRevealProps, "startFrame">;
};

const TYPE_START = 8;
const TYPE_END = 74;
const SUBMIT = 84;
const REVEAL = 112;

const Sparkle = ({ size, color }: { size: number; color: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path d="M12 0 C13 8 16 11 24 12 C16 13 13 16 12 24 C11 16 8 13 0 12 C8 11 11 8 12 0 Z" fill={color} />
  </svg>
);

// Mocked AI prompt sheet: the prompt types itself in, the primary button is
// pressed, a brief sparkle "working" beat, then the finished result.
// 165 frames (11 beats) fits it.
export const PromptMock = ({
  title,
  subtitle,
  prompt: PROMPT,
  chips = ["Best Match"],
  buttonLabel = "Create",
  workingLabel = "Creating…",
  reveal,
}: PromptMockProps) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const typed = Math.round(
    interpolate(frame, [TYPE_START, TYPE_END], [0, PROMPT.length], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
  );
  const caretOn = frame > TYPE_END ? Math.floor(frame / 8) % 2 === 0 : true;
  const press = interpolate(frame, [SUBMIT - 3, SUBMIT, SUBMIT + 4], [1, 0.95, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const creating = frame >= SUBMIT;
  const shimmer = ((frame - SUBMIT) % 24) / 24;
  const enter = spring({ frame, fps, config: { damping: 200 } });

  return (
    <AbsoluteFill style={{ background: "#D8D8DE" }}>
      <StatusBar />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 58,
          bottom: 0,
          background: "white",
          borderRadius: "38px 38px 0 0",
          transform: `translateY(${(1 - enter) * 60}px)`,
        }}
      >
        <div
          style={{
            position: "absolute",
            left: 16,
            top: 16,
            width: 44,
            height: 44,
            borderRadius: 22,
            background: "#F2F2F7",
            fontSize: 22,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          ✕
        </div>
        <div style={{ position: "absolute", left: 20, right: 20, top: 82 }}>
          <div style={{ fontSize: 22, fontWeight: 700 }}>{title}</div>
          <div style={{ fontSize: 15, color: "#8E8E93", marginTop: 6, lineHeight: 1.35 }}>
            {subtitle}
          </div>
          <div
            style={{
              marginTop: 20,
              padding: 16,
              borderRadius: 22,
              background: "white",
              boxShadow: "0 0 0 1px rgba(0,0,0,0.06), 0 6px 20px rgba(0,0,0,0.05)",
            }}
          >
            <div style={{ fontSize: 17, fontWeight: 600 }}>Prompt</div>
            <div
              style={{
                marginTop: 12,
                height: 168,
                borderRadius: 14,
                background: "#F2F2F7",
                padding: 14,
                fontSize: 17,
                lineHeight: 1.4,
                color: "#111",
              }}
            >
              {PROMPT.slice(0, typed)}
              <span style={{ color: SYSTEM_BLUE, opacity: caretOn ? 1 : 0, fontWeight: 300 }}>|</span>
            </div>
          </div>
          <div style={{ marginTop: 18, display: "flex", gap: 8 }}>
            {chips.map((chip, chipIndex) => (
              <div
                key={chip}
                style={{
                  padding: "8px 13px",
                  borderRadius: 18,
                  fontSize: 14,
                  whiteSpace: "nowrap",
                  fontWeight: 500,
                  background: chipIndex === 0 ? "rgba(10,132,255,0.16)" : "#F2F2F7",
                  color: chipIndex === 0 ? SYSTEM_BLUE : "#111",
                }}
              >
                {chip}
              </div>
            ))}
          </div>
        </div>
        <PrimaryButton
          style={{
            bottom: 46,
            transform: `scale(${press})`,
            background: typed === 0 ? "#C7C7CC" : creating
              ? `linear-gradient(100deg, #5E5CE6 ${shimmer * 100 - 30}%, #BF5AF2 ${shimmer * 100}%, #5E5CE6 ${shimmer * 100 + 30}%)`
              : SYSTEM_BLUE,
          }}
          label={
            creating ? (
              <>
                <Sparkle size={18} color="white" /> {workingLabel}
              </>
            ) : (
              buttonLabel
            )
          }
        />
      </div>
      <ResultReveal {...reveal} startFrame={REVEAL} />
      {/* A burst of sparkles as the pass lands. */}
      {frame >= REVEAL &&
        [0, 1, 2, 3, 4, 5].map((i) => {
          const local = frame - REVEAL - i * 2;
          const life = interpolate(local, [0, 6, 26], [0, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
          const angle = (i / 6) * Math.PI * 2 + 0.4;
          const dist = 150 + local * 2.5;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 201 + Math.cos(angle) * dist - 12,
                top: 330 + Math.sin(angle) * dist * 1.2 - 12,
                opacity: life,
                transform: `scale(${0.6 + life * 0.6}) rotate(${local * 6}deg)`,
              }}
            >
              <Sparkle size={24} color={i % 2 ? "#BF5AF2" : "#FFD60A"} />
            </div>
          );
        })}
    </AbsoluteFill>
  );
};
