import { Component, type ReactNode } from 'react'
import { TriangleAlert, RefreshCw } from 'lucide-react'

interface Props { children: ReactNode }
interface State { hasError: boolean; message?: string }

/** Prevents a single failing widget (e.g. a chart) from blanking the whole app. */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, message: error.message }
  }

  componentDidCatch(error: Error) {
    // eslint-disable-next-line no-console
    console.error('[FleetGuard] Render error caught by boundary:', error)
  }

  reset = () => this.setState({ hasError: false, message: undefined })

  render() {
    if (!this.state.hasError) return this.props.children
    return (
      <div className="grid place-items-center py-24 text-center">
        <div className="glass rounded-2xl p-8 max-w-md">
          <div className="grid place-items-center h-14 w-14 rounded-2xl bg-rose-500/10 text-rose-300 mx-auto mb-4">
            <TriangleAlert className="h-7 w-7" />
          </div>
          <div className="font-display font-semibold text-primary text-lg">Something went wrong</div>
          <p className="text-secondary text-sm mt-1.5">This view hit a render error. The rest of the dashboard is still available.</p>
          {this.state.message && <p className="text-muted text-xs mt-2 font-mono break-words">{this.state.message}</p>}
          <button onClick={this.reset}
            className="mt-5 inline-flex items-center gap-2 h-10 px-4 rounded-xl accent-gradient text-white text-[13px] font-semibold ring-glow hover:brightness-110 transition">
            <RefreshCw className="h-4 w-4" /> Retry
          </button>
        </div>
      </div>
    )
  }
}
