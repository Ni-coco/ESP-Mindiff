import 'package:flutter/material.dart';
import 'package:mindiff_app/app.dart';

void main() {
  runApp(const App());
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bienvenue sur Accueil'),
    );
  }
}

class _ProgrammePage extends StatelessWidget {
  const _ProgrammePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Programme à venir'),
    );
  }
}

class _CameraPage extends StatelessWidget {
  const _CameraPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Caméra (à implémenter)'),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profil utilisateur'),
    );
  }
}
