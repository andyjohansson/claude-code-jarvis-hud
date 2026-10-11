import type { Register } from 'claude-code'

// Draws the working line as an arc reactor: the spinning ring and pulsing
// core are animated in reactor.tsx, on the terminal's own frame clock.
export const register: Register = on => {
  on('ui.render', { component: 'Spinner' }, ($, e, next) => {
    if (e.surface !== 'terminal') {
      return next(e)
    }

    const { Client } = $.ui.resolve(e)
    const text = e.props.message ?? e.props.word
    const suffix = text.endsWith('…') ? '' : e.props.suffix

    return (
      <Client
        key={`reactor-${e.requestId}`}
        module="./reactor.tsx"
        props={{ text, suffix, mode: e.props.mode }}
      />
    )
  })
}
