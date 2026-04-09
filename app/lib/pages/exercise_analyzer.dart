import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

class ExerciseFeedback {
  final int repCount;
  final String phase;       // label de la phase courante
  final String advice;      // conseil textuel
  final Color skeletonColor;
  final Map<String, double> angles; // angles affichés (label → valeur)

  const ExerciseFeedback({
    required this.repCount,
    required this.phase,
    required this.advice,
    required this.skeletonColor,
    this.angles = const {},
  });
}

// ---------------------------------------------------------------------------
// Abstract base
// ---------------------------------------------------------------------------

abstract class ExerciseAnalyzer {
  String get name;
  String get iconAsset; // emoji ou chemin asset
  String get emoji;

  ExerciseFeedback analyze(Pose pose);
  void reset();

  // Utilitaire partagé — angle entre 3 landmarks (en degrés)
  double calcAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;
    return (atan2(cross.abs(), dot) * 180 / pi).abs();
  }

  ExerciseFeedback noBodyDetected(int repCount, String phase) {
    return ExerciseFeedback(
      repCount: repCount,
      phase: phase,
      advice: 'Positionnez tout le corps dans le cadre',
      skeletonColor: const Color(0xFF00E5FF),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. SQUAT — analyse genou + hanche + alignement dos
// ---------------------------------------------------------------------------

class SquatAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Squat';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '🏋️';

  int _repCount = 0;
  String _phase = 'standing';

  static const double _standThresh = 160.0;
  static const double _bottomThresh = 100.0;

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final lKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (lHip == null || lKnee == null || lAnkle == null || lShoulder == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final kneeAngle = (calcAngle(lHip, lKnee, lAnkle) +
            (rHip != null && rKnee != null && rAnkle != null
                ? calcAngle(rHip, rKnee, rAnkle)
                : calcAngle(lHip, lKnee, lAnkle))) /
        2;
    final hipAngle = calcAngle(lShoulder, lHip, lKnee);

    // Machine à états
    switch (_phase) {
      case 'standing':
        if (kneeAngle < _standThresh - 20) _phase = 'descending';
      case 'descending':
        if (kneeAngle <= _bottomThresh) {
          _phase = 'bottom';
        } else if (kneeAngle > _standThresh) {
          _phase = 'standing';
        }
      case 'bottom':
        if (kneeAngle > _bottomThresh + 15) _phase = 'ascending';
      case 'ascending':
        if (kneeAngle >= _standThresh) {
          _phase = 'standing';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(kneeAngle, hipAngle),
      skeletonColor: _color(kneeAngle, hipAngle),
      angles: {'Genou': kneeAngle, 'Hanche': hipAngle},
    );
  }

  String _advice(double knee, double hip) {
    switch (_phase) {
      case 'standing':
        return 'Pieds écartés largeur épaules, fléchissez les genoux';
      case 'descending':
        if (knee > 130) return 'Continuez à descendre, cuisses parallèles au sol';
        if (hip < 70) return '⚠️ Dos droit ! Pensez à garder le torse haut';
        if (knee > 110) return 'Poussez les genoux vers l\'extérieur';
        return 'Belle descente, continuez jusqu\'en bas';
      case 'bottom':
        if (knee > 105) return 'Descendez encore — cuisses sous parallèle idéalement';
        if (hip < 60) return '🔴 Dos trop penché ! Regardez devant vous';
        return '✅ Parfait ! Remontez en poussant sur les talons';
      case 'ascending':
        return 'Poussez sur les talons, gardez les genoux alignés sur les orteils';
      default:
        return '';
    }
  }

  Color _color(double knee, double hip) {
    if (_phase == 'standing') return const Color(0xFF00E5FF);
    if (hip < 65) return const Color(0xFFFF5252);
    if (_phase == 'bottom' && knee <= 105) return const Color(0xFF00E676);
    if (_phase == 'bottom') return const Color(0xFFFF9100);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'standing';
  }
}

// ---------------------------------------------------------------------------
// 2. DÉVELOPPÉ COUCHÉ (Bench Press) — angle coude + chemin de barre
// ---------------------------------------------------------------------------

class BenchPressAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Développé\ncouché';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '🛋️';

  int _repCount = 0;
  String _phase = 'top'; // bras tendus = top, descente = lowering, bas = bottom, poussée = pressing

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist    = pose.landmarks[PoseLandmarkType.rightWrist];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lAngle;
    final elbowAngle = (lAngle + rAngle) / 2;

    // Écartement coudes : angle entre les deux avant-bras
    // Coudes trop serrés ou trop ouverts ?
    double elbowFlare = 0;
    if (rShoulder != null && rElbow != null) {
      elbowFlare = (lElbow.x - rElbow.x).abs() /
          ((lShoulder.x - (rShoulder.x)).abs().clamp(1, double.infinity));
    }
    final isElbowTooWide = elbowFlare > 1.4; // coudes trop évasés (risque épaule)

    switch (_phase) {
      case 'top':
        if (elbowAngle < 145) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle <= 90) {
          _phase = 'bottom';
        } else if (elbowAngle > 155) {
          _phase = 'top';
        }
      case 'bottom':
        if (elbowAngle > 100) _phase = 'pressing';
      case 'pressing':
        if (elbowAngle >= 155) {
          _phase = 'top';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, isElbowTooWide),
      skeletonColor: _color(elbowAngle, isElbowTooWide),
      angles: {'Coude': elbowAngle},
    );
  }

  String _advice(double elbow, bool tooWide) {
    switch (_phase) {
      case 'top':
        return 'Bras tendus, omoplates serrées contre le banc, arc naturel';
      case 'lowering':
        if (tooWide) return '⚠️ Coudes trop évasés — gardez-les à 45-75° du corps';
        if (elbow > 120) return 'Descendez la barre vers le bas du pectoral';
        return 'Descente contrôlée, touchez le sternum bas';
      case 'bottom':
        if (tooWide) return '🔴 Rapprochez les coudes, protégez les épaules !';
        if (elbow > 95) return 'Descendez encore, barre au niveau du sternum';
        return '✅ Bonne amplitude ! Poussez fort';
      case 'pressing':
        if (tooWide) return '⚠️ Serrez les pectoraux, ramenez les coudes';
        return 'Poussez en légère diagonale vers le haut, verrouillez les coudes';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool tooWide) {
    if (tooWide && _phase != 'top') return const Color(0xFFFF5252);
    if (_phase == 'top') return const Color(0xFF00E5FF);
    if (_phase == 'bottom' && elbow <= 92) return const Color(0xFF00E676);
    if (_phase == 'bottom') return const Color(0xFFFF9100);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'top';
  }
}

// ---------------------------------------------------------------------------
// 3. POMPE (Push-up) — angle coude + alignement corps
// ---------------------------------------------------------------------------

class PushUpAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Pompe';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '💪';

  int _repCount = 0;
  String _phase = 'up';

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lElbowAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rElbowAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lElbowAngle;
    final elbowAngle = (lElbowAngle + rElbowAngle) / 2;

    // Alignement corps (épaule-hanche-cheville)
    double bodyAngle = 180.0;
    if (lHip != null && lAnkle != null) {
      bodyAngle = calcAngle(lShoulder, lHip, lAnkle);
    }

    // Machine à états
    switch (_phase) {
      case 'up':
        if (elbowAngle < 140) _phase = 'descending';
      case 'descending':
        if (elbowAngle <= 90) {
          _phase = 'bottom';
        } else if (elbowAngle > 155) {
          _phase = 'up';
        }
      case 'bottom':
        if (elbowAngle > 100) _phase = 'ascending';
      case 'ascending':
        if (elbowAngle >= 155) {
          _phase = 'up';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, bodyAngle),
      skeletonColor: _color(elbowAngle, bodyAngle),
      angles: {'Coude': elbowAngle, 'Corps': bodyAngle},
    );
  }

  String _advice(double elbow, double body) {
    // Corps droit = bodyAngle proche de 180°
    final isBodyStraight = body > 155;
    switch (_phase) {
      case 'up':
        if (!isBodyStraight) return '⚠️ Alignez épaules-hanches-pieds';
        return 'Position haute — bras tendus, corps gainé';
      case 'descending':
        if (!isBodyStraight) return '🔴 Corps en planche ! Ne creusez pas le bas du dos';
        if (elbow > 120) return 'Continuez à descendre, coudes à 45° du corps';
        return 'Bien, continuez la descente contrôlée';
      case 'bottom':
        if (!isBodyStraight) return '⚠️ Gainé ! Contractez les abdos et les fessiers';
        if (elbow > 95) return 'Descendez encore un peu';
        return '✅ Bonne profondeur !';
      case 'ascending':
        if (!isBodyStraight) return '⚠️ Corps gainé jusqu\'en haut !';
        return 'Poussez fort, bras vers l\'extension complète';
      default:
        return '';
    }
  }

  Color _color(double elbow, double body) {
    final isBodyStraight = body > 155;
    if (!isBodyStraight) return const Color(0xFFFF5252);
    if (_phase == 'up') return const Color(0xFF00E5FF);
    if (_phase == 'bottom' && elbow <= 95) return const Color(0xFF00E676);
    if (_phase == 'bottom') return const Color(0xFFFF9100);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'up';
  }
}

// ---------------------------------------------------------------------------
// 4. PLANCHE (Plank) — alignement épaule-hanche-cheville + temps
// ---------------------------------------------------------------------------

class PlankAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Planche';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '🧘';

  String _phase = 'waiting';
  DateTime? _startTime;
  int _seconds = 0;

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (lShoulder == null || lHip == null || lAnkle == null) {
      return noBodyDetected(_seconds, _phase);
    }

    // Alignement latéral : angle épaule-hanche-cheville proche de 180°
    final alignAngle = (calcAngle(lShoulder, lHip, lAnkle) +
            (rShoulder != null && rHip != null && rAnkle != null
                ? calcAngle(rShoulder, rHip, rAnkle)
                : calcAngle(lShoulder, lHip, lAnkle))) /
        2;

    final isGoodPlank = alignAngle > 155 && alignAngle < 200;

    if (isGoodPlank) {
      _startTime ??= DateTime.now();
      _seconds = DateTime.now().difference(_startTime!).inSeconds;
      _phase = 'holding';
    } else {
      if (_seconds > 3) _phase = 'rest'; // était en planche, maintenant sorti
      _startTime = null;
    }

    return ExerciseFeedback(
      repCount: _seconds, // Pour Plank = secondes tenues
      phase: _phase,
      advice: _advice(alignAngle, isGoodPlank),
      skeletonColor: _color(alignAngle, isGoodPlank),
      angles: {'Alignement': alignAngle},
    );
  }

  String _advice(double align, bool good) {
    switch (_phase) {
      case 'waiting':
        return 'Mettez-vous en position planche — bras tendus ou sur les coudes';
      case 'holding':
        if (align > 200) return '⚠️ Baissez les hanches ! Corps trop cambré';
        if (align < 155) return '⚠️ Levez les hanches ! Corps en V';
        if (_seconds < 10) return 'Bien ! Contractez abdos et fessiers';
        if (_seconds < 30) return '💪 Tenez bon ! ${_seconds}s — respirez lentement';
        return '🔥 Excellent ! ${_seconds}s — vous êtes dans la zone !';
      case 'rest':
        return '✅ Bonne planche ! Tenez $_seconds secondes. Reposez-vous';
      default:
        return 'Mettez-vous en position planche';
    }
  }

  Color _color(double align, bool good) {
    if (!good) return const Color(0xFFFF9100);
    if (_seconds > 30) return const Color(0xFF00E676);
    if (_seconds > 10) return const Color(0xFF69F0AE);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _seconds = 0;
    _phase = 'waiting';
    _startTime = null;
  }
}

// ---------------------------------------------------------------------------
// 5. TRACTION (Pull-up / Chin-up) — angle coude + hauteur menton
// ---------------------------------------------------------------------------

class PullUpAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Traction';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '🏗️';

  int _repCount = 0;
  String _phase = 'hanging'; // hanging → pulling → top → lowering

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist    = pose.landmarks[PoseLandmarkType.rightWrist];
    final nose      = pose.landmarks[PoseLandmarkType.nose];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lAngle;
    final elbowAngle = (lAngle + rAngle) / 2;

    // Menton au-dessus des mains = top de la traction
    final chinAboveBar = nose != null && lWrist.y > nose.y;

    // Balancement : delta horizontal épaule gauche/droite sur frames successives
    double shoulderSymmetry = 0;
    if (rShoulder != null) {
      shoulderSymmetry = (lShoulder.y - rShoulder.y).abs();
    }
    final isSwinging = shoulderSymmetry > 30;

    switch (_phase) {
      case 'hanging':
        if (elbowAngle < 150) _phase = 'pulling';
      case 'pulling':
        if (chinAboveBar || elbowAngle <= 60) {
          _phase = 'top';
        } else if (elbowAngle > 160) {
          _phase = 'hanging';
        }
      case 'top':
        if (elbowAngle > 70) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle >= 155) {
          _phase = 'hanging';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, chinAboveBar, isSwinging),
      skeletonColor: _color(elbowAngle, chinAboveBar, isSwinging),
      angles: {'Coude': elbowAngle},
    );
  }

  String _advice(double elbow, bool chinUp, bool swinging) {
    switch (_phase) {
      case 'hanging':
        return 'Bras tendus, épaules actives — engagez les dorsaux avant de tirer';
      case 'pulling':
        if (swinging) return '⚠️ Arrêtez de vous balancer ! Mouvement strict';
        if (elbow > 110) return 'Tirez les coudes vers les hanches, pas vers le bas';
        return 'Bien ! Ramenez le menton au-dessus de la barre';
      case 'top':
        if (!chinUp) return '⚠️ Montez encore — menton au-dessus de la barre';
        if (swinging) return '⚠️ Corps gainé, contrôlez la position';
        return '✅ Top ! Contractez les dorsaux et les biceps';
      case 'lowering':
        if (swinging) return '🔴 Descente contrôlée, ne vous laissez pas tomber';
        return 'Descendez lentement en 2-3s, bras en extension complète';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool chinUp, bool swinging) {
    if (swinging) return const Color(0xFFFF9100);
    if (_phase == 'top' && chinUp) return const Color(0xFF00E676);
    if (_phase == 'top' && !chinUp) return const Color(0xFFFF9100);
    if (_phase == 'hanging') return const Color(0xFF00E5FF);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'hanging';
  }
}

// ---------------------------------------------------------------------------
// 6. CURL BICEPS — amplitude coude, coude fixe au corps
// ---------------------------------------------------------------------------

class BicepCurlAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Curl\nbiceps';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '💪';

  int _repCount = 0;
  String _phase = 'down'; // down → curling → top → lowering

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist    = pose.landmarks[PoseLandmarkType.rightWrist];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lAngle;
    final elbowAngle = (lAngle + rAngle) / 2;

    // Coude qui "sort" du corps = cheating
    // On détecte si le coude monte (position Y du coude < épaule)
    final isElbowKicking = lElbow.y < lShoulder.y - 20;

    // Balancement du tronc : si les hanches bougent
    double trunkSway = 0;
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (lHip != null && rHip != null) {
      trunkSway = ((lHip.x + rHip.x) / 2 - (lShoulder.x + (rShoulder?.x ?? lShoulder.x)) / 2).abs();
    }
    final isCheating = trunkSway > 50 || isElbowKicking;

    switch (_phase) {
      case 'down':
        if (elbowAngle < 140) _phase = 'curling';
      case 'curling':
        if (elbowAngle <= 55) {
          _phase = 'top';
        } else if (elbowAngle > 155) {
          _phase = 'down';
        }
      case 'top':
        if (elbowAngle > 65) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle >= 155) {
          _phase = 'down';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, isCheating, isElbowKicking),
      skeletonColor: _color(elbowAngle, isCheating),
      angles: {'Coude': elbowAngle},
    );
  }

  String _advice(double elbow, bool cheating, bool elbowKicking) {
    switch (_phase) {
      case 'down':
        return 'Bras tendus, coudes collés au corps, prise supination';
      case 'curling':
        if (elbowKicking) return '🔴 Coude fixe ! Ne soulevez pas le coude';
        if (cheating) return '⚠️ Pas de balancement — isolez les biceps';
        if (elbow > 110) return 'Continuez à monter, concentration sur le biceps';
        return 'Bien ! Serrez fort en haut';
      case 'top':
        if (elbowKicking) return '⚠️ Coude fixe, contractez le biceps au maximum';
        return '✅ Contraction max ! Squeeze 1 seconde';
      case 'lowering':
        if (cheating) return '⚠️ Contrôlez la descente, résistez à la gravité';
        return 'Descendez lentement en 2-3s, extension complète en bas';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool cheating) {
    if (cheating) return const Color(0xFFFF5252);
    if (_phase == 'top' && elbow <= 55) return const Color(0xFF00E676);
    if (_phase == 'down') return const Color(0xFF00E5FF);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'down';
  }
}

// ---------------------------------------------------------------------------
// 7. ROWING HALTÈRE (Dumbbell Row) — angle coude + rétraction omoplate
// ---------------------------------------------------------------------------

class DumbbellRowAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Rowing\nhaltère';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '🚣';

  int _repCount = 0;
  String _phase = 'down'; // down → pulling → top → lowering

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist    = pose.landmarks[PoseLandmarkType.rightWrist];
    final lHip      = pose.landmarks[PoseLandmarkType.leftHip];
    final rHip      = pose.landmarks[PoseLandmarkType.rightHip];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    // On prend le coté avec le coude le plus fléchi (côté actif)
    final lAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lAngle;
    final elbowAngle = lAngle < rAngle ? lAngle : rAngle;

    // Dos plat : angle du tronc (dos incliné à ~45° c'est normal pour row)
    double trunkAngle = 90.0;
    if (lHip != null && rHip != null) {
      final hipMidY = (lHip.y + rHip.y) / 2;
      final shoulderMidY = (lShoulder.y + (rShoulder?.y ?? lShoulder.y)) / 2;
      final hipMidX = (lHip.x + rHip.x) / 2;
      final shoulderMidX = (lShoulder.x + (rShoulder?.x ?? lShoulder.x)) / 2;
      trunkAngle = (atan2((shoulderMidY - hipMidY).abs(),
              (shoulderMidX - hipMidX).abs() + 0.001) *
          180 / pi);
    }
    final isDosVoute = trunkAngle < 30; // dos trop arrondi

    switch (_phase) {
      case 'down':
        if (elbowAngle < 140) _phase = 'pulling';
      case 'pulling':
        if (elbowAngle <= 75) {
          _phase = 'top';
        } else if (elbowAngle > 155) {
          _phase = 'down';
        }
      case 'top':
        if (elbowAngle > 85) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle >= 155) {
          _phase = 'down';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, isDosVoute, trunkAngle),
      skeletonColor: _color(elbowAngle, isDosVoute),
      angles: {'Coude': elbowAngle, 'Tronc': trunkAngle},
    );
  }

  String _advice(double elbow, bool dosVoute, double trunk) {
    switch (_phase) {
      case 'down':
        if (dosVoute) return '🔴 Dos plat ! Cambrez légèrement les lombaires';
        return 'Dos incliné ~45°, bras tendu, haltère sous l\'épaule';
      case 'pulling':
        if (dosVoute) return '🔴 Rentrez les côtes, dos plat avant tout';
        if (elbow > 120) return 'Tirez le coude vers le plafond, pas vers l\'arrière';
        return 'Bien ! Rétractez l\'omoplate, amenez le coude en haut';
      case 'top':
        if (dosVoute) return '⚠️ Gardez le dos plat même en contraction';
        return '✅ Pincez l\'omoplate — serrez 1s, dorsaux bien contractés';
      case 'lowering':
        return 'Descendez lentement, étirez bien le grand dorsal en bas';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool dosVoute) {
    if (dosVoute) return const Color(0xFFFF5252);
    if (_phase == 'top' && elbow <= 80) return const Color(0xFF00E676);
    if (_phase == 'down') return const Color(0xFF00E5FF);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'down';
  }
}

// ---------------------------------------------------------------------------
// 8. DIPS — angle coude + inclinaison buste (triceps vs pectoraux)
// ---------------------------------------------------------------------------

class DipsAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Dips';
  @override
  String get iconAsset => '';
  @override
  String get emoji => '⬇️';

  int _repCount = 0;
  String _phase = 'top'; // top → lowering → bottom → pressing

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow    = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist    = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist    = pose.landmarks[PoseLandmarkType.rightWrist];
    final lHip      = pose.landmarks[PoseLandmarkType.leftHip];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lAngle;
    final elbowAngle = (lAngle + rAngle) / 2;

    // Inclinaison du buste : plus le buste est incliné en avant → plus on travaille les pectoraux
    double busteLean = 0;
    if (lHip != null) {
      final dx = lShoulder.x - lHip.x;
      final dy = lShoulder.y - lHip.y;
      busteLean = (atan2(dx.abs(), dy.abs()) * 180 / pi).abs();
    }
    final isTricepsFocus = busteLean < 15; // buste vertical = triceps
    final isPecFocus = busteLean > 25;     // buste penché = pectoraux
    final isTooBent = busteLean > 50;

    switch (_phase) {
      case 'top':
        if (elbowAngle < 145) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle <= 90) {
          _phase = 'bottom';
        } else if (elbowAngle > 155) {
          _phase = 'top';
        }
      case 'bottom':
        if (elbowAngle > 100) _phase = 'pressing';
      case 'pressing':
        if (elbowAngle >= 155) {
          _phase = 'top';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, busteLean, isTricepsFocus, isPecFocus, isTooBent),
      skeletonColor: _color(elbowAngle, isTooBent),
      angles: {'Coude': elbowAngle, 'Buste': busteLean},
    );
  }

  String _advice(double elbow, double lean, bool triceps, bool pec, bool tooBent) {
    switch (_phase) {
      case 'top':
        if (triceps) return 'Buste vertical — focus triceps. Penchez-vous pour cibler les pecs';
        if (pec) return 'Buste penché — focus pectoraux. Contrôlez bien la descente';
        return 'Position haute — choisissez votre inclinaison selon la cible';
      case 'lowering':
        if (tooBent) return '🔴 Buste trop penché ! Risque pour les épaules';
        if (elbow > 120) return 'Descendez — objectif 90° au coude';
        return 'Bonne descente contrôlée';
      case 'bottom':
        if (tooBent) return '🔴 Redressez-vous légèrement pour protéger les épaules';
        if (elbow > 95) return 'Descendez encore, 90° au coude minimum';
        return '✅ Bonne amplitude ! Poussez fort vers le haut';
      case 'pressing':
        if (tooBent) return '⚠️ Gardez le buste stable pendant la poussée';
        return 'Poussez jusqu\'à l\'extension complète, verrouillage des coudes';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool tooBent) {
    if (tooBent) return const Color(0xFFFF5252);
    if (_phase == 'top') return const Color(0xFF00E5FF);
    if (_phase == 'bottom' && elbow <= 92) return const Color(0xFF00E676);
    if (_phase == 'bottom') return const Color(0xFFFF9100);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'top';
  }
}

// ---------------------------------------------------------------------------
// 9. DÉVELOPPÉ ÉPAULES (Overhead Press) — angle coude/épaule + gainage
// ---------------------------------------------------------------------------

class OverheadPressAnalyzer extends ExerciseAnalyzer {
  @override
  String get name => 'Développé\népaules';
  @override
  String get emoji => '🙌';
  @override
  String get iconAsset => '';

  int _repCount = 0;
  String _phase = 'bottom';

  @override
  ExerciseFeedback analyze(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (lShoulder == null || lElbow == null || lWrist == null) {
      return noBodyDetected(_repCount, _phase);
    }

    final lElbowAngle = calcAngle(lShoulder, lElbow, lWrist);
    final rElbowAngle = (rShoulder != null && rElbow != null && rWrist != null)
        ? calcAngle(rShoulder, rElbow, rWrist)
        : lElbowAngle;
    final elbowAngle = (lElbowAngle + rElbowAngle) / 2;

    final wristAboveShoulder = lWrist.y < lShoulder.y - 30;

    double lumbArch = 0;
    if (lHip != null && rHip != null) {
      final hipMidX = (lHip.x + rHip.x) / 2;
      final shoulderMidX = (lShoulder.x + (rShoulder?.x ?? lShoulder.x)) / 2;
      lumbArch = (hipMidX - shoulderMidX).abs();
    }
    final hasArch = lumbArch > 40;

    switch (_phase) {
      case 'bottom':
        if (elbowAngle > 130) _phase = 'pressing';
      case 'pressing':
        if (wristAboveShoulder && elbowAngle > 155) {
          _phase = 'top';
        } else if (elbowAngle < 80) {
          _phase = 'bottom';
        }
      case 'top':
        if (elbowAngle < 140) _phase = 'lowering';
      case 'lowering':
        if (elbowAngle <= 90) {
          _phase = 'bottom';
          _repCount++;
        }
    }

    return ExerciseFeedback(
      repCount: _repCount,
      phase: _phase,
      advice: _advice(elbowAngle, wristAboveShoulder, hasArch),
      skeletonColor: _color(elbowAngle, hasArch),
      angles: {'Coude': elbowAngle},
    );
  }

  String _advice(double elbow, bool wristUp, bool arch) {
    switch (_phase) {
      case 'bottom':
        return 'Barre à hauteur épaules, coudes légèrement devant le corps';
      case 'pressing':
        if (arch) return '⚠️ Gainez le ventre ! Évitez de cambrer le dos';
        if (elbow < 130) return 'Poussez la barre vers le haut, bras se tendent';
        return 'Continuez à pousser, bras presque tendus';
      case 'top':
        if (!wristUp) return 'Poussez jusqu\'à l\'extension complète au-dessus';
        if (arch) return '🔴 Gainez ! Le cambrage fatigue les lombaires';
        return '✅ Extension complète ! Haussez les épaules pour shrug final';
      case 'lowering':
        if (arch) return '⚠️ Gainé pendant la descente aussi !';
        return 'Descendez lentement et de façon contrôlée sous le menton';
      default:
        return '';
    }
  }

  Color _color(double elbow, bool arch) {
    if (arch) return const Color(0xFFFF5252);
    if (_phase == 'top') return const Color(0xFF00E676);
    if (_phase == 'bottom') return const Color(0xFFFF9100);
    return const Color(0xFF00E5FF);
  }

  @override
  void reset() {
    _repCount = 0;
    _phase = 'bottom';
  }
}

// ---------------------------------------------------------------------------
// Registry des exercices
// ---------------------------------------------------------------------------

final List<ExerciseAnalyzer> kExercises = [
  SquatAnalyzer(),
  BenchPressAnalyzer(),
  PullUpAnalyzer(),
  PushUpAnalyzer(),
  BicepCurlAnalyzer(),
  DumbbellRowAnalyzer(),
  DipsAnalyzer(),
  OverheadPressAnalyzer(),
  PlankAnalyzer(),
];

/// Mapping analyzerKey → index dans kExercises
const kAnalyzerKeyToIndex = <String, int>{
  'squat': 0,
  'bench': 1,
  'pullup': 2,
  'pushup': 3,
  'curl': 4,
  'row': 5,
  'dips': 6,
  'ohp': 7,
  'plank': 8,
};
