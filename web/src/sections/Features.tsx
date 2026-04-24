import React from 'react'

interface Feature {
  id: string
  icon: React.ReactNode
  title: string
  text: string
  tag: string
  delay?: string
}

const features: Feature[] = [
  {
    id: 'feat1',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
        <circle cx="12" cy="13" r="4" /><circle cx="12" cy="13" r="1.5" fill="currentColor" />
      </svg>
    ),
    title: 'Vérification IA des mouvements',
    text: "Pointez votre caméra, commencez votre série. Mindiff détecte votre squelette en temps réel, compte vos répétitions et vous alerte si votre posture doit être corrigée. Comme un coach, mais toujours disponible.",
    tag: 'Intelligence artificielle',
  },
  {
    id: 'feat2',
    delay: '0.1s',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <rect x="2" y="14" width="20" height="6" rx="2" /><rect x="6" y="10" width="12" height="4" />
        <line x1="12" y1="20" x2="12" y2="23" /><circle cx="17" cy="7" r="3" />
        <path d="M17 4V2M14.3 5.3l-1.4-1.4M13 7h-2M14.3 8.7l-1.4 1.4M17 9v2M19.7 8.7l1.4 1.4M21 7h2M19.7 5.3l1.4-1.4" />
      </svg>
    ),
    title: 'Balance connectée ESP',
    text: "Pesez-vous chaque matin. Notre balance intelligente envoie automatiquement vos données à l'application — poids, tendance, objectif. Conçue en interne, aucune donnée ne quitte votre réseau local.",
    tag: 'Matériel connecté',
  },
  {
    id: 'feat3',
    delay: '0.2s',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="4" width="18" height="18" rx="2" />
        <line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" />
        <line x1="3" y1="10" x2="21" y2="10" /><path d="M9 16l2 2 4-4" />
      </svg>
    ),
    title: 'Programmes personnalisés',
    text: "Du débutant au confirmé. Mindiff construit votre programme semaine par semaine en fonction de ce que vous avez réellement accompli — pas de ce qui était prévu. L'adaptation permanente.",
    tag: 'Personnalisation',
  },
  {
    id: 'feat4',
    delay: '0.3s',
    icon: (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
      </svg>
    ),
    title: 'Tableau de bord complet',
    text: "Un graphique pour le poids, un pour les séances, un pour les calories. Tout ce qui compte, visible en deux secondes. L'historique complet depuis le jour 1.",
    tag: 'Suivi & Analyse',
  },
]

export default function Features() {
  return (
    <section id="features" className="features" aria-labelledby="features-title">
      <div className="container">
        <div className="section-header animate-on-scroll">
          <span className="section-label">Fonctionnalités</span>
          <h2 className="section-title" id="features-title">Tout ce dont vous avez besoin pour progresser</h2>
          <p className="section-subtitle">Une combinaison unique d'intelligence artificielle, de matériel connecté et de suivi personnalisé.</p>
        </div>
        <div className="features__grid">
          {features.map(f => (
            <article
              key={f.id}
              className="feature-card animate-on-scroll"
              style={f.delay ? { '--delay': f.delay } as React.CSSProperties : undefined}
              aria-labelledby={`${f.id}-title`}
            >
              <div className="feature-card__icon" aria-hidden="true">{f.icon}</div>
              <h3 className="feature-card__title" id={`${f.id}-title`}>{f.title}</h3>
              <p className="feature-card__text">{f.text}</p>
              <span className="feature-card__tag">{f.tag}</span>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
