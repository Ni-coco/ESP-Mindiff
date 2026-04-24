import { useEffect } from 'react'

export function useActiveNav() {
  useEffect(() => {
    const sections = document.querySelectorAll('section[id]')
    const navLinks = document.querySelectorAll<HTMLAnchorElement>('.navbar__links a[href^="#"]')
    if (!sections.length || !navLinks.length) return

    function update() {
      let current = ''
      sections.forEach(s => {
        if (s.getBoundingClientRect().top <= 120) current = s.id
      })
      navLinks.forEach(a => {
        a.classList.toggle('active', a.getAttribute('href')?.slice(1) === current)
      })
    }

    window.addEventListener('scroll', update, { passive: true })
    update()
    return () => window.removeEventListener('scroll', update)
  }, [])
}
