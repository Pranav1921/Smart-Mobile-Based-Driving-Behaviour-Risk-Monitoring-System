import '@/lib/chartSetup'
import { useEffect, useRef } from 'react'
import { Chart as ChartJS, type ChartOptions, type ChartType } from 'chart.js'
import { tooltipStyle } from '@/lib/chartSetup'

const baseTooltip = { ...tooltipStyle, displayColors: false }

function SafeChart({
  type,
  data,
  options,
  height,
}: {
  type: ChartType
  data: any
  options?: any
  height?: number
}) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const chartInstanceRef = useRef<ChartJS | null>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    // Safely destroy any active Chart.js instance associated with this canvas element
    const existingChart = ChartJS.getChart(canvas)
    if (existingChart) {
      existingChart.destroy()
    }
    if (chartInstanceRef.current) {
      chartInstanceRef.current.destroy()
      chartInstanceRef.current = null
    }

    try {
      chartInstanceRef.current = new ChartJS(canvas, {
        type,
        data,
        options: options as any,
      })
    } catch (err) {
      console.warn('[SmartDrive] Chart render error:', err)
    }

    return () => {
      if (chartInstanceRef.current) {
        chartInstanceRef.current.destroy()
        chartInstanceRef.current = null
      }
    }
  }, [type, data, options])

  return (
    <div style={{ height: height || '100%', width: '100%', position: 'relative' }}>
      <canvas ref={canvasRef} />
    </div>
  )
}

export function AreaLineChart({
  labels, series, height = 240,
}: {
  labels: string[]
  series: { name: string; data: number[]; color: string; fill?: boolean }[]
  height?: number
}) {
  const data = {
    labels,
    datasets: series.map((s) => ({
      label: s.name,
      data: s.data,
      borderColor: s.color,
      backgroundColor: (ctx: any) => {
        const chart = ctx?.chart
        if (!chart || !chart.chartArea || !chart.ctx) return 'transparent'
        const { ctx: c, chartArea } = chart
        const g = c.createLinearGradient(0, chartArea.top, 0, chartArea.bottom)
        g.addColorStop(0, s.color + '55')
        g.addColorStop(1, s.color + '00')
        return s.fill === false ? 'transparent' : g
      },
      fill: s.fill !== false,
      tension: 0.4,
      borderWidth: 2.5,
      pointRadius: 0,
      pointHoverRadius: 5,
      pointHoverBackgroundColor: s.color,
      pointHoverBorderColor: '#fff',
    })),
  }
  const options: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    animation: {
      duration: 1000,
      easing: 'easeInOutCubic',
    },
    plugins: {
      legend: {
        display: series.length > 1,
        labels: { usePointStyle: true, boxWidth: 6, padding: 16 },
      },
      tooltip: baseTooltip as any,
    },
    scales: {
      x: { grid: { display: false }, border: { display: false } },
      y: { grid: { display: false }, border: { display: false }, ticks: { maxTicksLimit: 5 } },
    },
  }
  return <SafeChart type="line" data={data} options={options} height={height} />
}

export function BarChartCard({
  labels, values, color = '#1B3B2B', height = 240, horizontal = false,
}: { labels: string[]; values: number[]; color?: string; height?: number; horizontal?: boolean }) {
  const data = {
    labels,
    datasets: [
      {
        data: values,
        backgroundColor: color + 'cc',
        hoverBackgroundColor: color,
        borderRadius: 8,
        borderSkipped: false,
        barThickness: horizontal ? 14 : 22,
      },
    ],
  }
  const options: ChartOptions<'bar'> = {
    indexAxis: horizontal ? 'y' : 'x',
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip: baseTooltip as any },
    scales: {
      x: { grid: { display: false }, border: { display: false } },
      y: { grid: { display: false }, border: { display: false } },
    },
  }
  return <SafeChart type="bar" data={data} options={options} height={height} />
}

export function DoughnutCard({
  labels, values, colors, height = 200,
}: { labels: string[]; values: number[]; colors: string[]; height?: number }) {
  const data = {
    labels,
    datasets: [
      {
        data: values,
        backgroundColor: colors,
        borderColor: 'rgba(5,7,15,0.6)',
        borderWidth: 3,
        hoverOffset: 6,
      },
    ],
  }
  const options: ChartOptions<'doughnut'> = {
    responsive: true,
    maintainAspectRatio: false,
    cutout: '68%',
    plugins: {
      legend: { position: 'right', labels: { usePointStyle: true, boxWidth: 8, padding: 12 } },
      tooltip: baseTooltip as any,
    },
  }
  return <SafeChart type="doughnut" data={data} options={options} height={height} />
}

export function RadarCard({
  labels, series, height = 260,
}: { labels: string[]; series: { name: string; data: number[]; color: string }[]; height?: number }) {
  const data = {
    labels,
    datasets: series.map((s) => ({
      label: s.name,
      data: s.data,
      borderColor: s.color,
      backgroundColor: s.color + '22',
      pointBackgroundColor: s.color,
      borderWidth: 2,
      pointRadius: 3,
    })),
  }
  const options: ChartOptions<'radar'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { usePointStyle: true, boxWidth: 6, padding: 14 } },
      tooltip: baseTooltip as any,
    },
    scales: {
      r: {
        grid: { display: false },
        angleLines: { display: false },
        pointLabels: { color: '#64748b', font: { size: 11 } },
        ticks: { display: false, backdropColor: 'transparent' },
        suggestedMin: 0,
        suggestedMax: 100,
      },
    },
  }
  return <SafeChart type="radar" data={data} options={options} height={height} />
}

export function Sparkline({ data, color = '#1B3B2B', height = 44 }: { data: number[]; color?: string; height?: number }) {
  const cfg = {
    labels: data.map((_, i) => i),
    datasets: [
      {
        data,
        borderColor: color,
        borderWidth: 2,
        tension: 0.4,
        pointRadius: 0,
        fill: true,
        backgroundColor: (ctx: any) => {
          const chart = ctx?.chart
          if (!chart || !chart.chartArea || !chart.ctx) return 'transparent'
          const { ctx: c, chartArea } = chart
          const g = c.createLinearGradient(0, chartArea.top, 0, chartArea.bottom)
          g.addColorStop(0, color + '44')
          g.addColorStop(1, color + '00')
          return g
        },
      },
    ],
  }
  const options: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip: { enabled: false } },
    scales: { x: { display: false }, y: { display: false } },
  }
  return <SafeChart type="line" data={cfg} options={options} height={height} />
}
