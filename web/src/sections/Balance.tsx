export default function Balance() {
  return (
    <section id="balance" className="balance" aria-labelledby="balance-title">
      <div className="container balance__inner">
        <div className="balance__visual animate-on-scroll" aria-hidden="true">
          <div className="scale-illustration">
            <div className="scale-body">
              <div className="scale-display">
                <div className="scale-display-top">
                  <span className="scale-weight">74.2</span>
                  <span className="scale-unit">kg</span>
                </div>
                <div className="scale-display-bottom">
                  <span className="scale-trend">▼ 0.3 vs hier</span>
                </div>
              </div>
              <div className="scale-surface" />
              <div className="scale-chips">
                <div className="scale-chip">
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
                    <rect x="2" y="2" width="20" height="20" rx="4" stroke="white" strokeWidth="2" />
                    <path d="M8 12h8M12 8v8" stroke="white" strokeWidth="1.5" strokeLinecap="round" />
                  </svg>
                  <span>ESP32</span>
                </div>
                <div className="scale-chip scale-chip--wifi">
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
                    <path d="M5 12.55a11 11 0 0 1 14.08 0M1.42 9a16 16 0 0 1 21.16 0M8.53 16.11a6 6 0 0 1 6.95 0M12 20h.01" stroke="white" strokeWidth="2" strokeLinecap="round" />
                  </svg>
                  <span>Wi-Fi</span>
                </div>
              </div>
              <div className="scale-feet">
                <span /><span /><span /><span />
              </div>
            </div>
            <div className="scale-glow" />
          </div>
        </div>

        <div className="balance__content animate-on-scroll" style={{ '--delay': '0.1s' } as React.CSSProperties}>
          <span className="section-label">Produit connecté</span>
          <h2 className="section-title" id="balance-title">
            La balance Mindiff —<br />pensée pour aller plus loin
          </h2>
          <p className="balance__text">
            Développée entièrement en interne à partir d'un microcontrôleur ESP, notre balance connectée mesure votre poids avec précision et communique en temps réel avec l'application. Pas de cloud tiers, pas d'abonnement caché — vos données vous appartiennent.
          </p>
          <div className="balance__pills" aria-label="Caractéristiques">
            <span className="pill">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M5 12.55a11 11 0 0 1 14.08 0M1.42 9a16 16 0 0 1 21.16 0M8.53 16.11a6 6 0 0 1 6.95 0M12 20h.01" />
              </svg>
              Connexion Wi-Fi
            </span>
            <span className="pill">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" />
                <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
              </svg>
              Synchronisation automatique
            </span>
          </div>
          <a href="#download" className="btn btn--primary">En savoir plus</a>
        </div>
      </div>
    </section>
  )
}
