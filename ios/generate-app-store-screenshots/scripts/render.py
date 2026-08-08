#!/usr/bin/env python3

"""Render deterministic App Store marketing screenshots."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ACCEPTED_SIZES = {
    # iPhone 6.9"
    "1260x2736": (1260, 2736),
    "1290x2796": (1290, 2796),
    "1320x2868": (1320, 2868),
    # iPad 13"
    "2048x2732": (2048, 2732),
    "2064x2752": (2064, 2752),
    "2732x2048": (2732, 2048),
    "2752x2064": (2752, 2064),
}
# Atmospheric type and spacing are tuned for the default iPhone canvas; scale
# them for larger App Store sizes (notably 13" iPad) so hierarchy stays balanced.
REFERENCE_CANVAS_WIDTH = 1320
DEFAULT_FONT = Path("/System/Library/Fonts/SFNSRounded.ttf")
EDITORIAL_FONT = Path("/System/Library/Fonts/SFNSRounded.ttf")
JAPANESE_FONT = Path("/System/Library/Fonts/Hiragino Sans GB.ttc")
KOREAN_FONT = Path("/System/Library/Fonts/AppleSDGothicNeo.ttc")
TEXT_COLOR = (8, 8, 12)
EYEBROW_COLOR = (104, 104, 110)
EDITORIAL_BORDER_COLOR = (232, 232, 234)
MIN_TEXT_CONTRAST = 4.5


def load_font(size: int, weight: str) -> ImageFont.FreeTypeFont:
    if not DEFAULT_FONT.exists():
        raise RuntimeError(f"Required SF Rounded font not found: {DEFAULT_FONT}")
    font = ImageFont.truetype(str(DEFAULT_FONT), size)
    try:
        font.set_variation_by_name(weight)
    except OSError as error:
        raise RuntimeError(f"SF Rounded does not provide the {weight} variation") from error
    return font


def load_editorial_font(size: int, weight: str, locale: str) -> ImageFont.FreeTypeFont:
    if locale == "ja":
        if not JAPANESE_FONT.exists():
            raise RuntimeError(f"Required Japanese font not found: {JAPANESE_FONT}")
        return ImageFont.truetype(str(JAPANESE_FONT), size, index=2 if weight == "Bold" else 0)
    if locale == "ko":
        if not KOREAN_FONT.exists():
            raise RuntimeError(f"Required Korean font not found: {KOREAN_FONT}")
        return ImageFont.truetype(str(KOREAN_FONT), size, index=6 if weight == "Bold" else 4)
    if not EDITORIAL_FONT.exists():
        raise RuntimeError(f"Required editorial font not found: {EDITORIAL_FONT}")
    font = ImageFont.truetype(str(EDITORIAL_FONT), size)
    try:
        font.set_variation_by_name(weight)
    except OSError as error:
        raise RuntimeError(f"SF Rounded does not provide the {weight} variation") from error
    return font


def text_width(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> int:
    bounds = draw.textbbox((0, 0), text, font=font)
    return bounds[2] - bounds[0]


def fit_font(
    draw: ImageDraw.ImageDraw,
    text: str,
    preferred_size: int,
    minimum_size: int,
    max_width: int,
    weight: str,
) -> ImageFont.FreeTypeFont:
    for size in range(preferred_size, minimum_size - 1, -2):
        font = load_font(size, weight)
        if text_width(draw, text, font) <= max_width:
            return font
    raise ValueError(f'Text is too long for the template: "{text}"')


def wrap_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
    max_lines: int,
) -> list[str]:
    if "\n" in text:
        lines: list[str] = []
        for segment in text.splitlines():
            remaining = max_lines - len(lines)
            if remaining < 1:
                raise ValueError(f"Text exceeds {max_lines} lines; shorten the copy")
            lines.extend(wrap_text(draw, segment, font, max_width, remaining))
        return lines

    character_wrap = " " not in text and text_width(draw, text, font) > max_width
    words = list(text) if character_wrap else text.split()
    separator = "" if character_wrap else " "
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current}{separator}{word}".strip()
        if not current or text_width(draw, candidate, font) <= max_width:
            current = candidate
            continue
        lines.append(current)
        current = word
    if current:
        lines.append(current)
    if len(lines) > max_lines:
        raise ValueError(f"Text exceeds {max_lines} lines; shorten the copy")
    return lines


def gradient(size: tuple[int, int], start: tuple[int, int, int], end: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    denominator = max(1, width - 1)
    for x in range(width):
        amount = x / denominator
        color = tuple(round(a + (b - a) * amount) for a, b in zip(start, end))
        for y in range(height):
            pixels[x, y] = color
    return image


def relative_luminance(color: tuple[int, int, int]) -> float:
    channels = []
    for value in color:
        channel = value / 255
        channels.append(channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def contrast_ratio(foreground: tuple[int, int, int], background: tuple[int, int, int]) -> float:
    lighter = max(relative_luminance(foreground), relative_luminance(background))
    darker = min(relative_luminance(foreground), relative_luminance(background))
    return (lighter + 0.05) / (darker + 0.05)


def validate_text_contrast(canvas: Image.Image, bounds: tuple[int, int, int, int], label: str) -> None:
    left, top, right, bottom = bounds
    crop = canvas.crop((max(0, left), max(0, top), min(canvas.width, right), min(canvas.height, bottom)))
    minimum = min(contrast_ratio(TEXT_COLOR, pixel) for pixel in crop.getdata())
    if minimum < MIN_TEXT_CONTRAST:
        raise ValueError(
            f"{label} contrast is {minimum:.2f}:1; expected at least {MIN_TEXT_CONTRAST:.1f}:1"
        )


def layout_scale(canvas_width: int, canvas_height: int | None = None) -> float:
    if canvas_height is not None and canvas_width > canvas_height:
        # Landscape iPad canvases are much wider but shorter than the reference
        # portrait canvas. Scale from height so type does not crowd the device.
        return canvas_height / 1650
    return canvas_width / REFERENCE_CANVAS_WIDTH


def scaled(value: int, scale: float) -> int:
    return max(1, round(value * scale))


def draw_headline(
    canvas: Image.Image,
    headline: str,
    emphasis: str,
    y: int,
    max_width: int,
) -> int:
    draw = ImageDraw.Draw(canvas)
    scale = layout_scale(canvas.width, canvas.height)
    font = fit_font(
        draw,
        headline,
        scaled(108, scale),
        scaled(76, scale),
        max_width,
        "Bold",
    )
    width = text_width(draw, headline, font)
    start_x = (canvas.width - width) // 2
    bounds = draw.textbbox((start_x, y), headline, font=font)
    height = bounds[3] - bounds[1]
    validate_text_contrast(canvas, bounds, "Headline")

    if not emphasis or emphasis not in headline:
        draw.text((start_x, y), headline, font=font, fill=TEXT_COLOR)
        return y + height

    prefix, suffix = headline.split(emphasis, 1)
    prefix_width = text_width(draw, prefix, font)
    emphasis_width = text_width(draw, emphasis, font)
    emphasis_x = start_x + prefix_width

    # Keep every glyph near-black for reliable contrast. The brand gradient is
    # decorative emphasis only, so readability never depends on its colors.
    draw.text((start_x, y), headline, font=font, fill=TEXT_COLOR)

    underline_y = bounds[3] + scaled(14, scale)
    underline_height = draw_emphasis_underline(
        canvas,
        x=emphasis_x,
        y=underline_y,
        width=emphasis_width,
        font_size=font.size,
    )
    return underline_y + underline_height


def draw_emphasis_underline(
    canvas: Image.Image,
    x: int,
    y: int,
    width: int,
    font_size: int,
) -> int:
    """Draw a clean, slightly heavy underline beneath emphasized copy."""
    stroke_width = max(8, font_size // 14)
    height = stroke_width + 4
    center_y = height // 2

    mask = Image.new("L", (width, height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.line(
        ((stroke_width // 2, center_y), (width - stroke_width // 2, center_y)),
        fill=255,
        width=stroke_width,
    )
    radius = stroke_width // 2
    for point_x in (radius, width - radius):
        mask_draw.ellipse(
            (point_x - radius, center_y - radius, point_x + radius, center_y + radius),
            fill=255,
        )

    underline = gradient((width, height), (244, 79, 128), (255, 137, 54))
    canvas.paste(underline, (x, y), mask)
    return height


def draw_editorial_copy(canvas: Image.Image, eyebrow: str, headline: str, locale: str) -> int:
    """Draw the restrained, editorial hierarchy used by the clean template."""
    draw = ImageDraw.Draw(canvas)
    horizontal_margin = round(canvas.width * 0.105)
    max_width = canvas.width - horizontal_margin * 2

    eyebrow_font = load_editorial_font(76, "Semibold", locale)
    if text_width(draw, eyebrow, eyebrow_font) > max_width:
        raise ValueError(f'Eyebrow is too long for the editorial template: "{eyebrow}"')
    eyebrow_width = text_width(draw, eyebrow, eyebrow_font)
    eyebrow_y = 236
    draw.text(
        ((canvas.width - eyebrow_width) // 2, eyebrow_y),
        eyebrow,
        font=eyebrow_font,
        fill=EYEBROW_COLOR,
    )

    headline_font = load_editorial_font(124, "Bold", locale)
    headline_lines = wrap_text(draw, headline, headline_font, max_width, 3)
    headline_y = 350
    line_height = headline_font.size + 4
    for index, line in enumerate(headline_lines):
        line_width = text_width(draw, line, headline_font)
        position = ((canvas.width - line_width) // 2, headline_y + index * line_height)
        bounds = draw.textbbox(position, line, font=headline_font)
        validate_text_contrast(canvas, bounds, f"Headline line {index + 1}")
        draw.text(position, line, font=headline_font, fill=TEXT_COLOR)

    return headline_y + len(headline_lines) * line_height


def render(args: argparse.Namespace) -> None:
    canvas_size = ACCEPTED_SIZES[args.size]
    background_path = Path(args.background).expanduser().resolve()
    device_path = Path(args.device_image).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if args.style == "editorial":
        canvas = Image.new("RGB", canvas_size, "white")
        border_inset = 6
        border_width = max(2, round(canvas.width / 440))
        ImageDraw.Draw(canvas).rounded_rectangle(
            (
                border_inset,
                border_inset,
                canvas.width - border_inset - 1,
                canvas.height - border_inset - 1,
            ),
            radius=96,
            outline=EDITORIAL_BORDER_COLOR,
            width=border_width,
        )
        draw_editorial_copy(canvas, args.eyebrow, args.headline, args.locale)
    else:
        background = Image.open(background_path).convert("RGB")
        background = background.resize(canvas_size, Image.Resampling.LANCZOS)
        canvas = Image.blend(
            Image.new("RGB", canvas_size, "white"),
            background,
            args.background_opacity,
        )

        scale = layout_scale(canvas.width, canvas.height)
        is_landscape = canvas.width > canvas.height
        headline_bottom = draw_headline(
            canvas,
            args.headline,
            args.emphasis,
            y=round(canvas.height * 0.055) if is_landscape else scaled(190, scale),
            max_width=canvas.width - scaled(150, scale),
        )

        draw = ImageDraw.Draw(canvas)
        subtitle_font = fit_font(
            draw,
            args.subtitle,
            preferred_size=scaled(50, scale),
            minimum_size=scaled(40, scale),
            max_width=canvas.width * 2,
            weight="Semibold",
        )
        subtitle_lines = wrap_text(
            draw,
            args.subtitle,
            subtitle_font,
            canvas.width - scaled(210, scale),
            2,
        )
        subtitle_y = headline_bottom + scaled(36 if is_landscape else 68, scale)
        line_height = subtitle_font.size + scaled(15, scale)
        for index, line in enumerate(subtitle_lines):
            width = text_width(draw, line, subtitle_font)
            line_position = ((canvas.width - width) // 2, subtitle_y + index * line_height)
            line_bounds = draw.textbbox(line_position, line, font=subtitle_font)
            validate_text_contrast(canvas, line_bounds, f"Subtitle line {index + 1}")
            draw.text(
                line_position,
                line,
                font=subtitle_font,
                fill=TEXT_COLOR,
            )

    device = Image.open(device_path)
    if "A" not in device.getbands():
        raise ValueError("Device image must contain transparency around its device frame")
    device = device.convert("RGBA")
    phone_width = round(canvas.width * args.phone_width_ratio)
    phone_height = round(device.height * phone_width / device.width)
    phone_y = round(canvas.height * args.phone_top_ratio)
    if args.style == "editorial":
        bottom_margin = round(canvas.height * 0.025)
        available_height = canvas.height - phone_y - bottom_margin
        if phone_height > available_height:
            phone_height = available_height
            phone_width = round(device.width * phone_height / device.height)
    device = device.resize((phone_width, phone_height), Image.Resampling.LANCZOS)
    phone_x = (canvas.width - phone_width) // 2
    canvas.paste(device, (phone_x, phone_y), device)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, format="PNG", optimize=True)
    validate(output_path, canvas_size)
    print(f"Rendered {output_path}")
    print(f"Size: {canvas_size[0]}x{canvas_size[1]} | mode: RGB | alpha: no")


def validate(path: Path, expected_size: tuple[int, int]) -> None:
    with Image.open(path) as image:
        if image.format != "PNG":
            raise RuntimeError(f"Expected PNG output, found {image.format}")
        if image.size != expected_size:
            raise RuntimeError(f"Expected {expected_size}, found {image.size}")
        if image.mode != "RGB" or "A" in image.getbands():
            raise RuntimeError("App Store screenshot must be opaque RGB without alpha")


def parse_args() -> argparse.Namespace:
    skill_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device-image", required=True, help="Transparent framed device PNG")
    parser.add_argument("--headline", required=True)
    parser.add_argument("--emphasis", default="", help="Exact headline phrase to emphasize")
    parser.add_argument("--subtitle", required=True)
    parser.add_argument(
        "--eyebrow",
        default="Designed for You",
        help="Short secondary line used by the editorial style",
    )
    parser.add_argument("--style", choices=("atmospheric", "editorial"), default="atmospheric")
    parser.add_argument("--locale", default="en-US")
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--background",
        default=str(skill_root / "assets" / "asc-screenshot-bg.png"),
    )
    parser.add_argument(
        "--background-opacity",
        type=float,
        default=0.8,
        help="Background artwork opacity over white (default: 0.8)",
    )
    parser.add_argument("--size", choices=sorted(ACCEPTED_SIZES), default="1320x2868")
    parser.add_argument("--phone-width-ratio", type=float)
    parser.add_argument("--phone-top-ratio", type=float)
    args = parser.parse_args()
    if args.phone_width_ratio is None:
        args.phone_width_ratio = 0.75 if args.style == "editorial" else 0.86
    if args.phone_top_ratio is None:
        args.phone_top_ratio = 0.265 if args.style == "editorial" else 0.255
    if not 0.65 <= args.phone_width_ratio <= 0.95:
        parser.error("--phone-width-ratio must be between 0.65 and 0.95")
    if not 0.20 <= args.phone_top_ratio <= 0.40:
        parser.error("--phone-top-ratio must be between 0.20 and 0.40")
    if not 0 <= args.background_opacity <= 1:
        parser.error("--background-opacity must be between 0 and 1")
    return args


if __name__ == "__main__":
    try:
        render(parse_args())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
