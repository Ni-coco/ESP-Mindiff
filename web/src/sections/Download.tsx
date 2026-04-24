import ApkQrCard from '../components/ApkQrCard'

const APK_PROD = 'https://github.com/Ni-coco/ESP-Mindiff/releases/download/main-latest/app-release.apk'
const APK_DEV  = 'https://github.com/Ni-coco/ESP-Mindiff/releases/download/dev-latest/app-release.apk'

export default function Download() {
  return (
    <section id="download" className="download" aria-labelledby="download-title">
      <div className="container download__inner">
        <div className="section-header animate-on-scroll">
          <h2 className="section-title" id="download-title">
            Prêt à transformer<br />votre entraînement ?
          </h2>
          <p className="section-subtitle">Disponible sur iOS et Android. Téléchargement gratuit.</p>
        </div>

        <div className="download__buttons animate-on-scroll" style={{ '--delay': '0.1s' } as React.CSSProperties}>
          <a href="#" className="store-btn" aria-label="Télécharger sur l'App Store">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            <div>
              <span className="store-btn__sub">Télécharger sur</span>
              <span className="store-btn__name">l'App Store</span>
            </div>
          </a>
          <a href="#" className="store-btn" aria-label="Disponible sur Google Play">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M3 20.5v-17c0-.83 1-.83 1.35-.36l14 8.5c.4.24.4.84 0 1.08l-14 8.5C3.95 21.53 3 21.2 3 20.5zM5 6.34V17.66L15.5 12 5 6.34z" />
            </svg>
            <div>
              <span className="store-btn__sub">Disponible sur</span>
              <span className="store-btn__name">Google Play</span>
            </div>
          </a>
        </div>

        <div className="apk-wrapper animate-on-scroll" style={{ '--delay': '0.2s' } as React.CSSProperties} aria-label="Téléchargement APK Android">
          <div className="apk-divider" aria-hidden="true">
            <span>ou téléchargez l'APK Android directement</span>
          </div>
          <div className="apk-grid">
            <ApkQrCard env="prod" url={APK_PROD} label="Version stable" />
            <ApkQrCard env="dev"  url={APK_DEV}  label="Version de développement" />
          </div>
        </div>
      </div>
    </section>
  )
}
