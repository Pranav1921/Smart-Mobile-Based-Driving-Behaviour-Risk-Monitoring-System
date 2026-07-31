import { createContext, useContext, useEffect, useState } from 'react'

type Theme = 'dark' | 'light'
const ThemeContext = createContext<{ theme: Theme; toggle: () => void }>({ theme: 'light', toggle: () => {} })

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() => 'light')

  useEffect(() => {
    const root = document.documentElement
    root.classList.add('light')
    root.classList.remove('dark')
    localStorage.setItem('fg-theme', 'light')
  }, [theme])

  return (
    <ThemeContext.Provider value={{ theme, toggle: () => {} }}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => useContext(ThemeContext)
