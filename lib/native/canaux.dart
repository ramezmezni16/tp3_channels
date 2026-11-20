
import 'package:flutter/services.dart';

class CanauxNatifs {
  // MethodChannels
  static const _infos = MethodChannel('appareil/infos');
  static const _vibreur = MethodChannel('appareil/vibrer');
  static const _permission = MethodChannel('audio/permission');
  static const _torche = MethodChannel('appareil/torche');

  // EventChannels
  static const _lumiere = EventChannel('capteur/lumiere');
  static const _audio = EventChannel('audio/niveau');
  static const _proximite = EventChannel('capteur/proximite');

  // Informations appareil
  static Future<Map<String, dynamic>> lireInfos() async {
    final infos = await _infos.invokeMapMethod<String, dynamic>('lire');
    return infos ?? {};
  }

  // Vibreur
  static Future<void> vibrer(String motif) =>
      _vibreur.invokeMethod('vibrer', {'motif': motif});

  // Capteur de lumière
  static Stream<double> lumiere() =>
      _lumiere.receiveBroadcastStream().map((v) => (v as num).toDouble());

  // Permission microphone
  static Future<bool> demanderMicro() async =>
      await _permission.invokeMethod<bool>('demander') ?? false;

  // Niveau sonore
  static Stream<double> niveauSonore() =>
      _audio.receiveBroadcastStream().map((v) => (v as num).toDouble());

  // Capteur de proximité
  static Stream<bool> proximite() =>
      _proximite.receiveBroadcastStream().map((v) => v as bool);

  // Torche
  static Future<void> changerTorche(bool etat) =>
      _torche.invokeMethod('changer', {'etat': etat});
}
