import { useState } from 'react'
import { QRCodeCanvas } from 'qrcode.react'

interface Props {
  env: 'prod' | 'dev'
  url: string
  label: string
}

export default function ApkQrCard({ env, url, label }: Props) {
  const [qrError, setQrError] = useState(false)

  const isProd = env === 'prod'

  return (
    <div className="apk-card">
      <span className={`apk-badge apk-badge--${env}`}>{isProd ? 'Prod' : 'Dev'}</span>
      <p className="apk-card__title">{label}</p>

      <div className="apk-qr" role="img" aria-label={`QR code — APK ${isProd ? 'Production' : 'Dev'}`}>
        {qrError ? (
          <img
            src={`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=${encodeURIComponent(url)}`}
            alt={`QR code ${isProd ? 'Production' : 'Dev'}`}
            width="140"
            height="140"
            onError={() => {/* si le fallback échoue aussi, on garde l'img cassée */ }}
          />
        ) : (
          <QRCodeCanvas
            value={url}
            size={140}
            fgColor="#121212"
            bgColor="#ffffff"
            level="M"
            onError={() => setQrError(true)}
          />
        )}
      </div>

      <p className="apk-card__hint">Scannez avec votre téléphone</p>

      <a
        href={url}
        className={`btn apk-card__btn${isProd ? ' btn--primary' : ' apk-card__btn--dev'}`}
        aria-label={`Télécharger l'APK version ${isProd ? 'Production' : 'développement'}`}
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
          <polyline points="7 10 12 15 17 10" />
          <line x1="12" y1="15" x2="12" y2="3" />
        </svg>
        Télécharger
      </a>
    </div>
  )
}
