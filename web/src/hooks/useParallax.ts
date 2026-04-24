import { useEffect } from 'react'

export function useParallax() {
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    if (window.innerWidth < 768) return

    const hero = document.getElementById('hero')
    const mockup = document.querySelector<HTMLElement>('.hero__mockup')
    if (!hero) return

    let ticking = false

    const onScroll = () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          const y = window.scrollY
          hero.style.backgroundPositionY = y * 0.3 + 'px'
          if (mockup) mockup.style.transform = `translateY(${y * -0.08}px)`
          ticking = false
        })
        ticking = true
      }
    }

    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])
}
