import { useEffect, useRef } from 'react'
import { useMap } from 'react-leaflet'
import L from 'leaflet'

export interface HeatPoint {
  lat: number
  lng: number
  intensity: number // 0..1
  color: string     // hex, e.g. '#ef4444'
}

interface Props {
  points: HeatPoint[]
  radius?: number   // px
  blur?: number     // px
  minOpacity?: number
}

/**
 * Pure canvas heatmap layer using leaflet's built-in SVGOverlay / canvasLayer.
 * No external dependencies — draws radial Gaussian blobs on an HTML5 Canvas
 * positioned and updated via react-leaflet's useMap hook.
 */
export function HeatmapLayer({ points, radius = 28, blur = 22, minOpacity = 0.08 }: Props) {
  const map = useMap()
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const overlayRef = useRef<L.Layer | null>(null)

  useEffect(() => {
    if (!map) return

    // Remove previous overlay
    if (overlayRef.current) {
      map.removeLayer(overlayRef.current)
      overlayRef.current = null
    }

    const redraw = () => {
      const size = map.getSize()
      const canvas = canvasRef.current!
      canvas.width = size.x
      canvas.height = size.y

      const ctx = canvas.getContext('2d')!
      ctx.clearRect(0, 0, size.x, size.y)

      // Draw each point as a radial gradient blob (true heatmap look)
      for (const p of points) {
        const pt = map.latLngToContainerPoint([p.lat, p.lng])
        const x = pt.x
        const y = pt.y

        // Parse hex color → rgb
        const r = parseInt(p.color.slice(1, 3), 16)
        const g = parseInt(p.color.slice(3, 5), 16)
        const b = parseInt(p.color.slice(5, 7), 16)

        const alpha = minOpacity + p.intensity * (1 - minOpacity) * 0.72

        const grad = ctx.createRadialGradient(x, y, 0, x, y, radius + blur)
        grad.addColorStop(0,   `rgba(${r},${g},${b},${alpha.toFixed(3)})`)
        grad.addColorStop(0.35,`rgba(${r},${g},${b},${(alpha * 0.65).toFixed(3)})`)
        grad.addColorStop(0.7, `rgba(${r},${g},${b},${(alpha * 0.2).toFixed(3)})`)
        grad.addColorStop(1,   `rgba(${r},${g},${b},0)`)

        ctx.beginPath()
        ctx.arc(x, y, radius + blur, 0, Math.PI * 2)
        ctx.fillStyle = grad
        ctx.fill()
      }
    }

    // Create a canvas pane overlay
    const pane = map.getPane('overlayPane')!
    const canvas = document.createElement('canvas')
    canvas.style.position = 'absolute'
    canvas.style.top = '0'
    canvas.style.left = '0'
    canvas.style.pointerEvents = 'none'
    canvas.style.zIndex = '300'
    pane.appendChild(canvas)
    canvasRef.current = canvas

    const sync = () => {
      const topLeft = map.containerPointToLayerPoint([0, 0])
      L.DomUtil.setPosition(canvas, topLeft)
      redraw()
    }

    map.on('move zoom viewreset moveend zoomend', sync)
    sync()

    // Store cleanup ref
    const cleanupCanvas = canvas
    const cleanupSync = sync
    overlayRef.current = { remove: () => {} } as unknown as L.Layer

    return () => {
      map.off('move zoom viewreset moveend zoomend', cleanupSync)
      cleanupCanvas.remove()
    }
  }, [map, points, radius, blur, minOpacity])

  return null
}
