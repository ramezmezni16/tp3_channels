
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native/canaux.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PageCanaux(),
    ));

class PageCanaux extends StatefulWidget {
  const PageCanaux({super.key});

  @override
  State<PageCanaux> createState() => _PageCanauxState();
}

class _PageCanauxState extends State<PageCanaux> {
  String _infos = 'Appuyez sur Lire';

  double? _lux;
  double? _db;
  bool? _proche;
  bool _torcheAllumee = false;

  StreamSubscription<double>? _abonnementLumiere;
  StreamSubscription<double>? _abonnementAudio;
  StreamSubscription<bool>? _abonnementProximite;

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  Widget _carte(String titre, List<Widget> contenu) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...contenu,
            ],
          ),
        ),
      );

  // 1. Informations appareil
  Future<void> _lireInfos() async {
    try {
      final i = await CanauxNatifs.lireInfos();

      if (!mounted) return;

      setState(() {
        _infos =
            '${i['marque']} ${i['modele']}\n'
            'Android ${i['version']} (API ${i['sdk']})';
      });
    } on PlatformException catch (e) {
      _message('Erreur : ${e.message}');
    }
  }

  // 2. Vibreur
  Future<void> _vibrer(String motif) async {
    try {
      await CanauxNatifs.vibrer(motif);
      _message('Vibration : $motif');
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // 3. Capteur de lumière
  void _basculerLumiere() {
    if (_abonnementLumiere == null) {
      _abonnementLumiere = CanauxNatifs.lumiere().listen(
        (lux) {
          if (mounted) {
            setState(() => _lux = lux);
          }
        },
        onError: (e) => _message('Capteur lumière : $e'),
      );
    } else {
      _abonnementLumiere!.cancel();
      _abonnementLumiere = null;
      _lux = null;
    }

    setState(() {});
  }

  // 4. Niveau sonore et permission microphone
  Future<void> _basculerMicro() async {
    if (_abonnementAudio != null) {
      await _abonnementAudio!.cancel();
      _abonnementAudio = null;
      _db = null;

      if (mounted) setState(() {});
      return;
    }

    try {
      final autorise = await CanauxNatifs.demanderMicro();

      if (!autorise) {
        _message('Permission microphone refusée');
        return;
      }

      _abonnementAudio = CanauxNatifs.niveauSonore().listen(
        (db) {
          if (mounted) {
            setState(() => _db = db);
          }
        },
        onError: (e) => _message('Micro : $e'),
      );

      if (mounted) setState(() {});
    } on PlatformException catch (e) {
      _message('Erreur microphone : ${e.message}');
    }
  }

  // 5. Capteur de proximité
  void _basculerProximite() {
    if (_abonnementProximite == null) {
      _abonnementProximite = CanauxNatifs.proximite().listen(
        (proche) {
          if (mounted) {
            setState(() => _proche = proche);
          }
        },
        onError: (e) => _message('Proximité : $e'),
      );
    } else {
      _abonnementProximite!.cancel();
      _abonnementProximite = null;
      _proche = null;
    }

    setState(() {});
  }

  // 6. Torche
  Future<void> _basculerTorche(bool etat) async {
    try {
      await CanauxNatifs.changerTorche(etat);

      if (mounted) {
        setState(() => _torcheAllumee = etat);
      }
    } on PlatformException catch (e) {
      _message('Torche : ${e.message}');
    }
  }

  @override
  void dispose() {
    _abonnementLumiere?.cancel();
    _abonnementAudio?.cancel();
    _abonnementProximite?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TP 3 – Platform Channels'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Informations appareil
          _carte('1. Informations appareil (MethodChannel)', [
            Text(_infos),
            FilledButton(
              onPressed: _lireInfos,
              child: const Text('Lire'),
            ),
          ]),

          // 2. Vibreur
          _carte('2. Vibreur (MethodChannel)', [
            Wrap(
              spacing: 8,
              children: [
                for (final motif in ['court', 'long', 'sos', 'disco'])
                  FilledButton.tonal(
                    onPressed: () => _vibrer(motif),
                    child: Text(motif),
                  ),
              ],
            ),
          ]),

          // 3. Capteur de lumière
          _carte('3. Capteur de lumière (EventChannel)', [
            Text(
              _lux == null
                  ? 'Non démarré'
                  : '${_lux!.toStringAsFixed(1)} lux',
            ),
            FilledButton(
              onPressed: _basculerLumiere,
              child: Text(
                _abonnementLumiere == null ? 'Démarrer' : 'Arrêter',
              ),
            ),
          ]),

          // 4. Niveau sonore
          _carte('4. Niveau sonore (EventChannel)', [
            Text(
              _db == null
                  ? 'Non démarré'
                  : '${_db!.toStringAsFixed(1)} dBFS',
            ),
            LinearProgressIndicator(
              value: (((_db ?? -90) + 90) / 90).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerMicro,
              child: Text(
                _abonnementAudio == null
                    ? 'Démarrer micro'
                    : 'Arrêter micro',
              ),
            ),
          ]),

          // 5. Capteur de proximité
          _carte('5. Capteur de proximité (EventChannel)', [
            Text(
              _proche == null
                  ? 'Non démarré'
                  : (_proche! ? 'Objet proche' : 'Aucun objet proche'),
            ),
            FilledButton(
              onPressed: _basculerProximite,
              child: Text(
                _abonnementProximite == null ? 'Démarrer' : 'Arrêter',
              ),
            ),
          ]),

          // 6. Torche
          _carte('6. Torche (MethodChannel)', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Flash LED'),
              value: _torcheAllumee,
              onChanged: _basculerTorche,
            ),
          ]),
        ],
      ),
    );
  }
}
