import { useNavbar } from '../hooks/useNavbar'

export default function Navbar() {
  const { isScrolled, isMenuOpen, toggleMenu, closeMenu } = useNavbar()

  return (
    <header className={`navbar${isScrolled ? ' is-scrolled' : ''}`} id="navbar" role="banner">
      <div className="container navbar__inner">
        <a href="#hero" className="navbar__logo" aria-label="Mindiff — Accueil">
          <span className="logo-icon" aria-hidden="true">
            <img src="/assets/icons/Mindiff.png" alt="" width="32" height="32" style={{ borderRadius: 8 }} />
          </span>
          <span className="logo-text">Mindiff</span>
        </a>
        <nav className="navbar__nav" aria-label="Navigation principale">
          <ul className="navbar__links" role="list">
            <li><a href="#features">Fonctionnalités</a></li>
            <li><a href="#how-it-works">Comment ça marche</a></li>
            <li><a href="#balance">La Balance</a></li>
            <li><a href="#download" className="btn btn--nav white">Télécharger</a></li>
          </ul>
        </nav>
        <button
          className={`navbar__hamburger${isMenuOpen ? ' is-open' : ''}`}
          id="hamburger"
          aria-label={isMenuOpen ? 'Fermer le menu' : 'Ouvrir le menu'}
          aria-expanded={isMenuOpen}
          aria-controls="mobile-menu"
          onClick={toggleMenu}
        >
          <span /><span /><span />
        </button>
      </div>
      <nav
        className={`navbar__mobile${isMenuOpen ? ' is-open' : ''}`}
        id="mobile-menu"
        aria-label="Menu mobile"
        aria-hidden={!isMenuOpen}
      >
        <ul role="list">
          <li><a href="#features" onClick={closeMenu}>Fonctionnalités</a></li>
          <li><a href="#how-it-works" onClick={closeMenu}>Comment ça marche</a></li>
          <li><a href="#balance" onClick={closeMenu}>La Balance</a></li>
          <li><a href="#download" onClick={closeMenu}>Télécharger</a></li>
        </ul>
      </nav>
    </header>
  )
}
