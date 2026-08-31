import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MinimalistVisualizer extends StatelessWidget {
  final int? albumId;
  final bool isPlaying;
  final double size;
  final Color glowColor;

  /// Factor de escala base (estado "Pausa").
  ///
  /// Reduce el tamaño resultante multiplicando el tamaño que recibe por este
  /// factor. Con `0.75` la animación se muestra a 3/4 (25% menor) del tamaño
  /// original. Para cambiar el tamaño en pausa, edita este valor:
  ///   - Más grande  -> aumentar (p. ej. `0.9`)
  ///   - Más pequeño -> disminuir (p. ej. `0.5`)
  static const double pausedSizeFactor = 0.75;

  /// Incremento aplicado al pasar de "Pausa" a "Reproducir". Aumenta el
  /// tamaño un 25% (1/4) respecto al de pausa. Para ajustarlo, edita este
  /// valor: `1.25` aumenta 1/4, `1.5` aumentaría la mitad, `1.0` lo deja igual.
  static const double playingGrowth = 1.25;

  /// Factor de redondez de las esquinas. Cuanto menor, más "cuadrado".
  /// Usa `1.0` para muy redondeado o `0.35` para esquinas sutiles.
  static const double cornerRoundness = 0.35;

  const MinimalistVisualizer({
    super.key,
    this.albumId,
    this.isPlaying = false,
    this.size = 260,
    this.glowColor = const Color(0xFF6D28D9),
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño base en pausa, ampliado 1/4 al reproducir.
    final baseFactor = isPlaying ? pausedSizeFactor * playingGrowth : pausedSizeFactor;
    final scaledSize = size * baseFactor;
    // La resolución de la portada se solicita en un tamaño mayor al mostrado
    // (downscaling): se pide `size` grande a alta `quality` y se dibuja a la
    // medida real, quedando así nítida en lugar de ampliada/borrosa.
    final displayRes = scaledSize * 0.85;
    final requestedRes = (scaledSize * 1.5).round().clamp(256, 2048);

    final outerPadding = (scaledSize * 0.035).clamp(8.0, 14.0);
    final artSize = scaledSize - outerPadding * 2;
    final radius = (artSize * 0.065 * cornerRoundness).clamp(2.0, 10.0);

    // Ancho del anillo de definición. El recorte de la imagen usa su mismo
    // radio descontando el borde, para que las esquinas sigan exactamente el
    // contorno del cuadro de la animación.
    const frameBorder = 1.2;
    final imageRadius = (radius - frameBorder).clamp(1.0, 9.0);

    return SizedBox(
      width: scaledSize,
      height: scaledSize,
      child: Padding(
        padding: EdgeInsets.all(outerPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              // Resplandor exterior suave (glow)
              BoxShadow(
                color: glowColor.withAlpha(75),
                blurRadius: 40,
                spreadRadius: 4,
                offset: const Offset(0, 6),
              ),
              // Sombra de profundidad para definir el borde
              BoxShadow(
                color: Colors.black.withAlpha(140),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
            // Anillo de definición que hace que el recorte de esquinas
            // se vea limpio y no "comido" por la sombra.
            border: Border.all(
              color: Colors.white.withAlpha(20),
              width: frameBorder,
            ),
          ),
          child: ClipRRect(
            // La imagen sigue el mismo contorno del cuadro: mismo radio
            // descontando el anillo, con antialiasing en las esquinas.
            borderRadius: BorderRadius.circular(imageRadius),
            clipBehavior: Clip.antiAlias,
            child: ColoredBox(
              color: const Color(0xFF111111),
              child: albumId != null
                  ? QueryArtworkWidget(
                      id: albumId!,
                      type: ArtworkType.ALBUM,
                      size: requestedRes,
                      quality: 100,
                      artworkFit: BoxFit.cover,
                      artworkWidth: displayRes,
                      artworkHeight: displayRes,
                      artworkQuality: FilterQuality.high,
                      artworkScale: 1.0,
                      artworkBorder: BorderRadius.circular(imageRadius),
                      keepOldArtwork: true,
                      nullArtworkWidget: _defaultArt(artSize),
                    )
                  : _defaultArt(artSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultArt(double side) => Container(
        color: const Color(0xFF1C1C1C),
        alignment: Alignment.center,
        child: Icon(Icons.music_note_rounded,
            color: Colors.white54, size: side * 0.42),
      );
}