import { expect, test } from 'claude-code/testing'

const SPINNER = {
  plugin: 'jarvis-reactor',
  component: 'Spinner',
  requestId: 'main',
  props: { word: 'Calibrating repulsors', message: null, suffix: '…', mode: 'responding' },
} as const

const IN = { in: 'reactor-main' }

// The reactor's eight braille cells, two rows of four.
const ring = async (ui: { findAll: (q: object) => Promise<{ text?: string }[]> }) =>
  (await ui.findAll({ type: 'Text', ...IN }))
    .map(t => t.text ?? '')
    .filter(t => t.length === 1 && t >= '\u2800' && t <= '\u28ff')
    .join('')

test('the terminal spinner becomes a spinning reactor with the verb', async $ => {
  const ui = await $.ui.mount({ ...SPINNER, surface: 'terminal' })

  expect(await ui.find({ type: 'Text', text: /esc to interrupt/, ...IN })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'C', ...IN })).toBeDefined()

  const first = await ring(ui)
  await ui.advance(500)
  const second = await ring(ui)

  expect(first).toHaveLength(8)
  expect(second).toHaveLength(8)
  expect(second).not.toBe(first)
  await ui.unmount()
})

test('a message overrides the verb', async $ => {
  const ui = await $.ui.mount({
    ...SPINNER,
    surface: 'terminal',
    props: { ...SPINNER.props, message: 'Compacting conversation' },
  })
  const line = (await ui.findAll({ type: 'Text', ...IN })).map(t => t.text).join('')

  expect(line).toContain('Compacting conversation…')
  expect(line).not.toContain('Calibrating')
  await ui.unmount()
})

test('the desktop keeps its own spinner', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>engine spinner</Text>
  })
  const ui = await $.ui.mount({ ...SPINNER, surface: 'desktop' })

  expect(await ui.find({ type: 'Client' })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: 'engine spinner' })).toBeDefined()
  await ui.unmount()
})
