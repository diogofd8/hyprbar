pragma Singleton

import QtQuick
import Quickshell

// Opaque OKLCH seeds as Oxidye accepts them, with the sRGB and HSV conversions
// needed to edit and display them. Seed and array arguments stay untyped so
// parse() can reject malformed JSON values itself instead of coercing them.
Singleton {
    // Greys have no hue, so their seeds keep the OKLCH hue of this saturation as
    // metadata. Unlike full saturation, which folds back near blue, it rises
    // monotonically around the circle and can be inverted exactly.
    readonly property real referenceSaturation: 0.75

    function normalizeHue(hue: real): real {
        return ((hue % 360) + 360) % 360
    }

    // The seed syntax supported by oxidye: opaque OKLCH, with optional % / deg.
    function parse(seed): var {
        if (typeof seed !== "string") return null
        const match = /^oklch\(\s*(.*?)\s*\)$/i.exec(seed.trim())
        if (!match) return null
        const parts = match[1].split(/\s+/)
        if (parts.length !== 3) return null
        const number = /^[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?$/i
        const percent = parts[0].endsWith("%")
        const lightness = percent ? parts[0].slice(0, -1) : parts[0]
        const hue = parts[2].replace(/deg$/i, "")
        if (![lightness, parts[1], hue].every(part => number.test(part))) return null
        const l = Number(lightness) / (percent ? 100 : 1)
        const c = Number(parts[1])
        const h = Number(hue)
        if (![l, c, h].every(Number.isFinite) || l < 0 || l > 1 || c < 0) return null
        return {lightness: l, chroma: c, hue: normalizeHue(h), alpha: 1}
    }

    function format(seed, hue: real): string {
        const h = normalizeHue(Number(normalizeHue(hue).toFixed(7)))
        return "oklch(" + seed.lightness.toFixed(9) + " " + seed.chroma.toFixed(9)
            + " " + h.toFixed(7) + ")"
    }

    // OKLCH -> Oklab -> linear sRGB, D65. CSS Color 4 conversion equations:
    // https://www.w3.org/TR/css-color-4/#color-conversion-code
    function linearRgb(l: real, c: real, h: real): var {
        const angle = h * Math.PI / 180
        const a = c * Math.cos(angle), b = c * Math.sin(angle)
        const x = Math.pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
        const y = Math.pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
        const z = Math.pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)
        return [
            4.0767416621 * x - 3.3077115913 * y + 0.2309699292 * z,
            -1.2684380046 * x + 2.6097574011 * y - 0.3413193965 * z,
            -0.0041960863 * x - 0.7034186147 * y + 1.7076147010 * z
        ]
    }

    function encode(channel: real): real {
        return channel <= 0.0031308 ? 12.92 * channel
            : 1.055 * Math.pow(channel, 1 / 2.4) - 0.055
    }

    function decode(channel: real): real {
        return channel <= 0.04045 ? channel / 12.92
            : Math.pow((channel + 0.055) / 1.055, 2.4)
    }

    // Encoded sRGB -> linear sRGB -> Oklab -> OKLCH, inverting linearRgb:
    // https://bottosson.github.io/posts/oklab/
    function fromRgb(rgb): var {
        const [r, g, b] = rgb.map(channel => decode(channel))
        const x = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        const y = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        const z = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        const labA = 1.9779984951 * x - 2.4285922050 * y + 0.4505937099 * z
        const labB = 0.0259040371 * x + 0.7827717662 * y - 0.8086757660 * z
        return {
            lightness: 0.2104542553 * x + 0.7936177850 * y - 0.0040720468 * z,
            chroma: Math.hypot(labA, labB),
            hue: normalizeHue(Math.atan2(labB, labA) * 180 / Math.PI),
            alpha: 1
        }
    }

    function inGamut(l: real, c: real, h: real): bool {
        // Match the generator's serialized coefficients and gamut tolerance.
        return linearRgb(Math.round(l * 1e9) / 1e9, Math.round(c * 1e9) / 1e9,
            Math.round(h * 1e7) / 1e7).map(channel => encode(channel))
            .every(channel => Number.isFinite(channel) && channel >= -1e-7 && channel <= 1 + 1e-7)
    }

    function displayRgb(l: real, c: real, h: real): var {
        // Only the display copy is gamut mapped. The submitted seed stays intact.
        let chroma = c
        if (!inGamut(l, chroma, h)) {
            if (l <= 0 || l >= 1) {
                chroma = 0
            } else {
                let low = 0, high = Math.min(chroma, 1)
                for (let i = 0; i < 40; ++i) {
                    const mid = (low + high) / 2
                    if (inGamut(l, mid, h)) low = mid
                    else high = mid
                }
                chroma = Math.max(0, low - 1e-9)
            }
        }
        return linearRgb(l, chroma, h).map(channel => Math.max(0, Math.min(1, encode(channel))))
    }

    function displayColor(l: real, c: real, h: real): color {
        const rgb = displayRgb(l, c, h)
        return Qt.rgba(rgb[0], rgb[1], rgb[2], 1)
    }

    // Black or white, whichever reads better on an opaque sRGB background.
    function contrastInk(background: color): color {
        const light = 0.2126 * decode(background.r) + 0.7152 * decode(background.g) + 0.0722 * decode(background.b)
        return light > 0.179 ? "#000000" : "#FFFFFF"
    }

    // Encoded sRGB in 0..1 <-> HSV, with hue in degrees and saturation/value in 0..1.
    function hsvToRgb(h: real, s: real, v: real): var {
        const sector = normalizeHue(h) / 60
        const channel = n => {
            const k = (n + sector) % 6
            return v - v * s * Math.max(0, Math.min(k, 4 - k, 1))
        }
        return [channel(5), channel(3), channel(1)]
    }

    function rgbToHsv(rgb): var {
        const [r, g, b] = rgb
        const max = Math.max(r, g, b), delta = max - Math.min(r, g, b)
        let h = 0
        if (delta > 0) {
            if (max === r) h = 60 * (g - b) / delta
            else if (max === g) h = 60 * ((b - r) / delta + 2)
            else h = 60 * ((r - g) / delta + 4)
        }
        return {hue: normalizeHue(h), saturation: max > 0 ? delta / max : 0, value: max}
    }

    function hsvColor(h: real, s: real, v: real): color {
        const rgb = hsvToRgb(h, s, v)
        return Qt.rgba(rgb[0], rgb[1], rgb[2], 1)
    }

    function referenceHue(h: real): real {
        return fromRgb(hsvToRgb(h, referenceSaturation, 1)).hue
    }

    // The HSV hue whose reference colour has this OKLCH hue, by bisection.
    function hsvHue(oklchHue: real): real {
        const start = referenceHue(0)
        const unwrap = hue => hue < start ? hue + 360 : hue
        const target = unwrap(normalizeHue(oklchHue))
        let low = 0, high = 360
        for (let i = 0; i < 50; ++i) {
            const mid = (low + high) / 2
            if (unwrap(referenceHue(mid)) < target) low = mid
            else high = mid
        }
        return normalizeHue((low + high) / 2)
    }

    // The opaque OKLCH seed for an HSV colour, ready for format().
    function fromHsv(h: real, s: real, v: real): var {
        const color = fromRgb(hsvToRgb(h, s, v))
        // Exact greys still convert with ~4e-8 chroma and a meaningless hue.
        if (s <= 0 || v <= 0) {
            color.chroma = 0
            color.hue = referenceHue(h)
        }
        // Rounding must never push L past 1, which parse() and Oxidye reject.
        color.lightness = Math.max(0, Math.min(1, color.lightness))
        return color
    }

    // Slider position for a seed: the HSV of its displayed, gamut-mapped colour.
    function toHsv(seed): var {
        const hsv = rgbToHsv(displayRgb(seed.lightness, seed.chroma, seed.hue))
        if (hsv.saturation < 1e-7) {
            hsv.saturation = 0
            hsv.hue = hsvHue(seed.hue)
        }
        return hsv
    }
}
