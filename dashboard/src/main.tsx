import React, { StrictMode } from 'react'
import * as ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { ThemeProvider } from './lib/theme'
import { ErrorBoundary } from './components/ui/ErrorBoundary'
import { SocketProvider } from './hooks/SocketContext'
import App from './App.tsx'
import './index.css'

const createRootFn = (ReactDOM as any).createRoot || (ReactDOM as any).default?.createRoot || (ReactDOM as any).default || ReactDOM
const root = createRootFn.createRoot
  ? createRootFn.createRoot(document.getElementById('root')!)
  : createRootFn(document.getElementById('root')!)

root.render(
  <StrictMode>
    <ThemeProvider>
      <SocketProvider>
        <BrowserRouter>
          <ErrorBoundary>
            <App />
          </ErrorBoundary>
        </BrowserRouter>
      </SocketProvider>
    </ThemeProvider>
  </StrictMode>,
)
