import './styles/globals.css'

import Navbar from './sections/Navbar'
import Hero from './sections/Hero'
import Features from './sections/Features'
import HowItWorks from './sections/HowItWorks'
import Balance from './sections/Balance'
import Download from './sections/Download'
import Footer from './sections/Footer'

import { useScrollAnimation } from './hooks/useScrollAnimation'
import { useCounters } from './hooks/useCounters'
import { useParallax } from './hooks/useParallax'
import { useActiveNav } from './hooks/useActiveNav'
import { useSmoothScroll } from './hooks/useSmoothScroll'

export default function App() {
  useScrollAnimation()
  useCounters()
  useParallax()
  useActiveNav()
  useSmoothScroll()

  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Features />
        <HowItWorks />
        <Balance />
        <Download />
      </main>
      <Footer />
    </>
  )
}
