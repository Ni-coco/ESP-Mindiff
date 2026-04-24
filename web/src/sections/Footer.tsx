export default function Footer() {
  return (
    <footer className="footer" role="contentinfo">
      <div className="container footer__inner">
        <div className="footer__brand">
          <a href="#hero" className="navbar__logo" aria-label="Mindiff — Retour en haut">
            <span className="logo-icon" aria-hidden="true">
              <img src="/assets/icons/Mindiff.png" alt="" width="28" height="28" style={{ borderRadius: 7 }} />
            </span>
            <span className="logo-text">Mindiff</span>
          </a>
          <p className="footer__tagline">L'intelligence au service de votre corps.</p>
        </div>
        <nav className="footer__nav" aria-label="Liens du footer">
          <div className="footer__col">
            <h4>Application</h4>
            <ul role="list">
              <li><a href="#features">Fonctionnalités</a></li>
              <li><a href="#how-it-works">Comment ça marche</a></li>
              <li><a href="#download">Télécharger</a></li>
            </ul>
          </div>
          <div className="footer__col">
            <h4>Produits</h4>
            <ul role="list">
              <li><a href="#balance">Balance connectée</a></li>
            </ul>
          </div>
          <div className="footer__col">
            <h4>Contact</h4>
            <ul role="list">
              <li><a href="mailto:contact@mindiff.app">contact@mindiff.app</a></li>
            </ul>
          </div>
        </nav>
      </div>
      <div className="footer__bottom">
        <div className="container">
          <p>&copy; 2025 Mindiff. Tous droits réservés.</p>
          <a href="#">Politique de confidentialité</a>
        </div>
      </div>
    </footer>
  )
}
