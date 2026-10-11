import type { ClientModule } from 'claude-code'

type Props = { text: string; suffix: string; mode: string }
type State = { start: number; tick: number }

const TICK_MS = 50

// The reactor is an 8x8 grid of braille dots, four cells across and two
// rows down, laid out like the Claudian welcome reactor: an outer ring of
// segments sweeping clockwise, an empty band, two inner arcs turning the
// other way, and an empty center. Speeds match the Claudian CSS.
const DOTS = 8
const SEGMENT = 4 // ring positions per segment, the last one a gap
const RING_TURN_MS = 3000
const ARC_TURN_MS = 2200

// Braille dot bits by column and row within a cell.
const BIT = [
  [0x01, 0x02, 0x04, 0x40],
  [0x08, 0x10, 0x20, 0x80],
]

type Rgb = readonly [number, number, number]
const DIM: Rgb = [0, 110, 140]
const CYAN: Rgb = [0, 216, 255]
const CORE: Rgb = [230, 251, 255]
const TAU = 2 * Math.PI

const mix = (a: Rgb, b: Rgb, t: number) => {
  const k = Math.max(0, Math.min(1, t))
  const hex = a.map((v, i) => Math.round(v + (b[i]! - v) * k).toString(16).padStart(2, '0'))

  return `#${hex.join('')}`
}

// A cell's color from the average light of its lit dots: dim cyan, through
// arc reactor cyan, to the white-hot core.
const shade = (light: number) =>
  light < 0.62 ? mix(DIM, CYAN, light * 1.6) : mix(CYAN, CORE, (light - 0.62) * 2.6)

type Cell = { glyph: string; color: string }

type Dot = readonly [number, number]

// Clockwise from the top, so a step along the list is a step round the ring.
const angle = ([x, y]: Dot) => {
  const c = (DOTS - 1) / 2

  return (Math.atan2(x - c, c - y) + TAU) % TAU
}
const clockwise = (dots: Dot[]) => [...dots].sort((a, b) => angle(a) - angle(b))
const grid = Array.from({ length: DOTS * DOTS }, (_, i): Dot => [i % DOTS, Math.floor(i / DOTS)])
const inset = ([x, y]: Dot) => [Math.min(x, DOTS - 1 - x), Math.min(y, DOTS - 1 - y)] as const

// The outer edge with its corners trimmed round: 20 positions.
const OUTER = clockwise(
  grid.filter(d => {
    const [ix, iy] = inset(d)

    return (ix === 0 && iy >= 2) || (iy === 0 && ix >= 2) || (ix === 1 && iy === 1)
  }),
)

// A small ring two dots in, corners left out: 8 positions.
const INNER = clockwise(
  grid.filter(d => {
    const [ix, iy] = inset(d)

    return (ix === 2 && iy === 3) || (iy === 2 && ix === 3)
  }),
)

const reactor = (ms: number): Cell[][] => {
  const step = Math.floor(ms / (RING_TURN_MS / OUTER.length)) % OUTER.length
  const counter = Math.floor(ms / (ARC_TURN_MS / INNER.length)) % INNER.length
  const lit = new Map<Dot, number>()

  // Segments brighten toward the head of the sweep, like the conic tail.
  OUTER.forEach((dot, i) => {
    if ((i - step + OUTER.length) % SEGMENT !== SEGMENT - 1) {
      const behind = (step - i + OUTER.length) % OUTER.length
      lit.set(dot, 0.3 + 0.7 * (1 - behind / OUTER.length) ** 2)
    }
  })
  // Two arcs of three, opposite each other.
  INNER.forEach((dot, i) => {
    if ((i + counter) % 4 !== 3) {
      lit.set(dot, 0.55)
    }
  })

  const cells = Array.from({ length: DOTS / 4 }, () =>
    Array.from({ length: DOTS / 2 }, () => ({ bits: 0, light: 0, count: 0 })),
  )
  for (const [[x, y], light] of lit) {
    const cell = cells[y >> 2]![x >> 1]!
    cell.bits |= BIT[x & 1]![y & 3]!
    cell.light += light
    cell.count += 1
  }

  return cells.map(row =>
    row.map(c => ({
      glyph: String.fromCharCode(0x2800 + c.bits),
      color: shade(c.count ? c.light / c.count : 0),
    })),
  )
}

const elapsed = (ms: number) => {
  const s = Math.floor(ms / 1000)

  return s < 60 ? `${s}s` : `${Math.floor(s / 60)}m ${s % 60}s`
}

const Reactor: ClientModule<Props, State> = (props, surface) => {
  const { Box, Text } = surface.elements

  if (surface.state === undefined) {
    const start = Date.now()
    surface.setState({ start, tick: 0 })
    surface.every(TICK_MS, () => surface.setState({ start, tick: (surface.state?.tick ?? 0) + 1 }))
  }

  const { start, tick } = surface.state ?? { start: Date.now(), tick: 0 }
  const ms = tick * TICK_MS
  const rows = reactor(ms)

  // A highlight that sweeps across the words, like the HUD scan line.
  const label = `${props.text}${props.suffix}`
  const sweep = Math.floor(ms / 80) % (label.length + 12)

  return (
    <Box flexDirection="row">
      <Box flexDirection="column">
        {rows.map(row => (
          <Text>
            {row.map(cell => (
              <Text color={cell.color}>{cell.glyph}</Text>
            ))}
          </Text>
        ))}
      </Box>
      <Box flexDirection="column" marginLeft={1}>
        <Text>
          {[...label].map((ch, i) => (
            <Text color={Math.abs(i - sweep) <= 1 ? 'claudeShimmer' : 'claude'}>{ch}</Text>
          ))}
        </Text>
        <Text color="inactive">
          ({elapsed(Date.now() - start)}{props.mode === 'thinking' ? ' · thinking' : ''} · esc to interrupt)
        </Text>
      </Box>
    </Box>
  )
}

export default Reactor
