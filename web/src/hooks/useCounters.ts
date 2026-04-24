import { useEffect } from 'react'

function easeOut(t: number) {
  return 1 - Math.pow(1 - t, 3)
}

export function useCounters() {
  useEffect(() => {
    const nums = document.querySelectorAll<HTMLElement>('.stat-num[data-target]')
    if (!nums.length) return

    function animateCounter(el: HTMLElement) {
      const target = parseInt(el.dataset.target ?? '0', 10)
      const suffix = el.dataset.suffix ?? ''
      const duration = 1400
      let start: number | null = null

      function step(ts: number) {
        if (!start) start = ts
        const progress = Math.min((ts - start) / duration, 1)
        el.textContent = Math.round(easeOut(progress) * target) + suffix
        if (progress < 1) requestAnimationFrame(step)
      }
      requestAnimationFrame(step)
    }

    if (!('IntersectionObserver' in window)) {
      nums.forEach(animateCounter)
      return
    }

    const observer = new IntersectionObserver(
      entries => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            animateCounter(entry.target as HTMLElement)
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.5 }
    )

    nums.forEach(el => observer.observe(el))
    return () => observer.disconnect()
  }, [])
}
