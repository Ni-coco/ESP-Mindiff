export default function Hero() {
  return (
    <section id="hero" className="hero" aria-labelledby="hero-title">
      <div className="hero__particles" aria-hidden="true">
        {Array.from({ length: 8 }).map((_, i) => <span key={i} className="particle" />)}
      </div>
      <div className="container hero__inner">
        <div className="hero__content">
          <span className="hero__eyebrow animate-on-scroll">Application de fitness intelligente</span>
          <h1 className="hero__title animate-on-scroll" id="hero-title">
            Bougez mieux.<br /><span className="gradient-text">Devenez meilleur.</span>
          </h1>
          <p className="hero__subtitle animate-on-scroll">
            Mindiff analyse vos mouvements en temps réel, suit votre composition corporelle et vous guide vers vos objectifs — tout depuis votre smartphone.
          </p>
          <div className="hero__ctas animate-on-scroll">
            <a href="#download" className="btn btn--primary">Télécharger l'application</a>
            <a href="#features" className="btn btn--ghost">Découvrir les fonctionnalités <span aria-hidden="true">↓</span></a>
          </div>
        </div>

        <div className="hero__mockup animate-on-scroll" aria-hidden="true">
          <div className="phone-frame">
            <div className="phone-screen">
              <div className="phone-notch" />
              <div className="phone-ui">
                <div className="ui-header">
                  <div className="ui-avatar" />
                  <div className="ui-greeting">
                    <div className="ui-line ui-line--short" />
                    <div className="ui-line ui-line--medium" />
                  </div>
                </div>
                <div className="ui-camera-preview">
                  <div className="camera-skeleton">
                    <div className="skeleton-joint sj-head" />
                    <div className="skeleton-bone sb-torso" />
                    <div className="skeleton-bone sb-arm-l" />
                    <div className="skeleton-bone sb-arm-r" />
                    <div className="skeleton-bone sb-leg-l" />
                    <div className="skeleton-bone sb-leg-r" />
                    <div className="camera-badge">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                        <circle cx="12" cy="12" r="10" stroke="#22c55e" strokeWidth="2" />
                        <path d="M8 12l3 3 5-5" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" />
                      </svg>
                      <span>IA active</span>
                    </div>
                  </div>
                </div>
                <div className="ui-stats">
                  <div className="ui-stat">
                    <div className="ui-line ui-line--tiny" />
                    <div className="ui-stat-num">12</div>
                  </div>
                  <div className="ui-stat">
                    <div className="ui-line ui-line--tiny" />
                    <div className="ui-stat-num">74.2</div>
                  </div>
                  <div className="ui-stat">
                    <div className="ui-line ui-line--tiny" />
                    <div className="ui-stat-num">87%</div>
                  </div>
                </div>
                <div className="ui-progress-bar"><div className="ui-progress-fill" /></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="hero__stats" aria-label="Chiffres clés">
        <div className="container hero__stats-inner">
          <div className="stat-item">
            <span className="stat-num" data-target="50" data-suffix="+" aria-label="Plus de 50 exercices">0</span>
            <span className="stat-label">Exercices disponibles</span>
          </div>
          <div className="stat-item">
            <span className="stat-num" data-target="100" data-suffix="+" aria-label="Plus de 100 séances guidées">0</span>
            <span className="stat-label">Séances guidées</span>
          </div>
          <div className="stat-item">
            <span className="stat-num" data-target="75" data-suffix="+" aria-label="Plus de 75 programmes personnalisés">0</span>
            <span className="stat-label">Programmes personnalisés</span>
          </div>
        </div>
      </div>
    </section>
  )
}
