import React from 'react'

const steps = [
  {
    n: '01',
    icon: (
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
      </svg>
    ),
    title: 'Créez votre profil en 2 minutes',
    text: "Renseignez votre âge, poids, objectif et niveau. L'application génère immédiatement un programme de départ sur mesure.",
  },
  {
    n: '02',
    delay: '0.15s',
    icon: (
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
        <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
        <circle cx="12" cy="13" r="4" />
      </svg>
    ),
    title: "Filmez-vous pendant l'exercice",
    text: "Posez votre téléphone face à vous, lancez la session. L'IA compte et valide chaque répétition en temps réel avec un retour visuel instantané.",
  },
  {
    n: '03',
    delay: '0.3s',
    icon: (
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
        <line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" />
      </svg>
    ),
    title: 'Suivez votre transformation',
    text: "Après chaque séance et chaque pesée, votre tableau de bord se met à jour automatiquement. Visualisez vos progrès sur la durée.",
  },
]

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="how-it-works" aria-labelledby="hiw-title">
      <div className="container">
        <div className="section-header section-header--light animate-on-scroll">
          <span className="section-label">Comment ça marche</span>
          <h2 className="section-title section-title--light" id="hiw-title">Simple. Efficace. Intelligent.</h2>
          <p className="section-subtitle section-subtitle--light">Trois étapes pour transformer votre entraînement.</p>
        </div>
        <div className="steps">
          {steps.map((s, i) => (
            <React.Fragment key={s.n}>
              {i > 0 && <div className="steps__connector" aria-hidden="true" />}
              <div
                className="step animate-on-scroll"
                style={s.delay ? { '--delay': s.delay } as React.CSSProperties : undefined}
              >
                <div className="step__number" aria-hidden="true">{s.n}</div>
                <div className="step__icon" aria-hidden="true">{s.icon}</div>
                <h3 className="step__title">{s.title}</h3>
                <p className="step__text">{s.text}</p>
              </div>
            </React.Fragment>
          ))}
        </div>
      </div>
    </section>
  )
}
