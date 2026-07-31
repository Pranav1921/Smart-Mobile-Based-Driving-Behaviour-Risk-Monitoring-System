import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  RadialLinearScale,
  Filler,
  Tooltip,
  Legend,
} from 'chart.js'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  RadialLinearScale,
  Filler,
  Tooltip,
  Legend,
)

ChartJS.defaults.color = '#9aa7c2'
ChartJS.defaults.font.family = "'Inter', sans-serif"
ChartJS.defaults.font.size = 11

export const gridColor = 'rgba(255,255,255,0.05)'
export const tooltipStyle = {
  backgroundColor: 'rgba(10,16,32,0.95)',
  borderColor: 'rgba(34,211,238,0.25)',
  borderWidth: 1,
  padding: 10,
  cornerRadius: 10,
  titleColor: '#f1f5fb',
  bodyColor: '#9aa7c2',
}

export function cyanGradient(ctx: CanvasRenderingContext2D, h = 220) {
  const g = ctx.createLinearGradient(0, 0, 0, h)
  g.addColorStop(0, 'rgba(34,211,238,0.35)')
  g.addColorStop(1, 'rgba(34,211,238,0)')
  return g
}
