import '@/lib/chartSetup'
import { Line, Doughnut, Radar, Bar } from 'react-chartjs-2'
import type { ChartOptions } from 'chart.js'
import { gridColor, tooltipStyle } from '@/lib/chartSetup'

const baseTooltip = { ...tooltipStyle, displayColors: false }

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
        const { ctx: c, chartArea } = ctx.chart
        if (!chartArea) return 'transparent'
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
    responsive: true, maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    animation: {
      duration: 1000,
      easing: 'easeInOutCubic',
    },
    plugins: { legend: { display: series.length > 1, labels: { usePointStyle: true, boxWidth: 6, padding: 16 } }, tooltip: baseTooltip as any },
    scales: {
      x: { grid: { display: false }, border: { display: false } },
      y: { grid: { display: false }, border: { display: false }, ticks: { maxTicksLimit: 5 } },
    },
  }
  return <div style={{ height }}><Line data={data} options={options} /></div>
}

export function BarChartCard({
  labels, values, color = '#22d3ee', height = 240, horizontal = false,
}: { labels: string[]; values: number[]; color?: string; height?: number; horizontal?: boolean }) {
  const data = { labels, datasets: [{ data: values, backgroundColor: color + 'cc', hoverBackgroundColor: color, borderRadius: 8, borderSkipped: false, barThickness: horizontal ? 14 : 22 }] }
  const options: ChartOptions<'bar'> = {
    indexAxis: horizontal ? 'y' : 'x',
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip: baseTooltip as any },
    scales: {
      x: { grid: { display: false }, border: { display: false } },
      y: { grid: { display: false }, border: { display: false } },
    },
  }
  return <div style={{ height }}><Bar data={data} options={options} /></div>
}

export function DoughnutCard({
  labels, values, colors, height = 200,
}: { labels: string[]; values: number[]; colors: string[]; height?: number }) {
  const data = { labels, datasets: [{ data: values, backgroundColor: colors, borderColor: 'rgba(5,7,15,0.6)', borderWidth: 3, hoverOffset: 6 }] }
  const options: ChartOptions<'doughnut'> = {
    responsive: true, maintainAspectRatio: false, cutout: '68%',
    plugins: { legend: { position: 'right', labels: { usePointStyle: true, boxWidth: 8, padding: 12 } }, tooltip: baseTooltip as any },
  }
  return <div style={{ height }}><Doughnut data={data} options={options} /></div>
}

export function RadarCard({
  labels, series, height = 260,
}: { labels: string[]; series: { name: string; data: number[]; color: string }[]; height?: number }) {
  const data = {
    labels,
    datasets: series.map((s) => ({
      label: s.name, data: s.data,
      borderColor: s.color, backgroundColor: s.color + '22',
      pointBackgroundColor: s.color, borderWidth: 2, pointRadius: 3,
    })),
  }
  const options: ChartOptions<'radar'> = {
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { labels: { usePointStyle: true, boxWidth: 6, padding: 14 } }, tooltip: baseTooltip as any },
    scales: {
      r: {
        grid: { display: false }, angleLines: { display: false },
        pointLabels: { color: '#64748b', font: { size: 11 } },
        ticks: { display: false, backdropColor: 'transparent' },
        suggestedMin: 0, suggestedMax: 100,
      },
    },
  }
  return <div style={{ height }}><Radar data={data} options={options} /></div>
}

export function Sparkline({ data, color = '#22d3ee', height = 44 }: { data: number[]; color?: string; height?: number }) {
  const cfg = {
    labels: data.map((_, i) => i),
    datasets: [{ data, borderColor: color, borderWidth: 2, tension: 0.4, pointRadius: 0,
      fill: true,
      backgroundColor: (ctx: any) => {
        const { ctx: c, chartArea } = ctx.chart
        if (!chartArea) return 'transparent'
        const g = c.createLinearGradient(0, chartArea.top, 0, chartArea.bottom)
        g.addColorStop(0, color + '44'); g.addColorStop(1, color + '00'); return g
      } }],
  }
  const options: ChartOptions<'line'> = {
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { display: false }, tooltip: { enabled: false } },
    scales: { x: { display: false }, y: { display: false } },
  }
  return <div style={{ height }}><Line data={cfg} options={options} /></div>
}
