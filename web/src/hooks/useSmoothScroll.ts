import { useEffect } from 'react'

export function useSmoothScroll() {
  useEffect(() => {
    const navbarH = parseInt(
      getComputedStyle(document.documentElement).getPropertyValue('--navbar-h') || '72',
      10
    )

    const onClick = (e: MouseEvent) => {
      const anchor = (e.target as Element).closest('a[href^="#"]') as HTMLAnchorElement | null
      if (!anchor) return
      const href = anchor.getAttribute('href')
      if (!href || href === '#') return
      const target = document.querySelector(href)
      if (!target) return
      e.preventDefault()
      const top = target.getBoundingClientRect().top + window.scrollY - navbarH
      window.scrollTo({ top, behavior: 'smooth' })
    }

    document.addEventListener('click', onClick)
    return () => document.removeEventListener('click', onClick)
  }, [])
}
